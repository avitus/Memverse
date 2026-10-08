# OAuth PKCE Deploy Runbook

Deploys the OAuth/CORS changes from PR #397 to production, plus the Swagger UI
client reconciliation added alongside this runbook.

Staging (`staging.memverse.com`) is unreachable, so this deploy goes straight to
production. Every behaviour below is covered by specs; the steps here cover what
specs cannot see: the contents of the production `oauth_applications` table.

## What changes for whom

| Client | Before | After |
|---|---|---|
| iOS app (`avitus/Memverse_iOS`) | password grant, non-expiring token | unchanged |
| Android/Flutter app (`anirac-tech/memverse_project`) | password grant, non-expiring token | unchanged |
| Website (Devise session) | unchanged | unchanged |
| PWA (`memverse-pwa`) | did not exist | authorization code + S256 PKCE, 2 hour tokens, rotating refresh |
| Swagger UI at `/api` | implicit grant | authorization code + S256 PKCE (needs step 4) |
| Existing access tokens | valid | still valid; non-expiring tokens stay non-expiring |

The mobile apps keep working through a temporary compatibility shim in
`config/initializers/doorkeeper.rb`. See `spec/requests/legacy_password_grant_spec.rb`.

## 1. Pre-flight (read-only)

Run this in a production Rails console **before** deploying. It changes nothing
and prints no secrets:

```bash
cd /home/avitus/memverse.com/current && RAILS_ENV=production bundle exec rails console
```

```ruby
recent = Doorkeeper::AccessToken.where('created_at > ?', 30.days.ago).group(:application_id).count
Doorkeeper::Application.order(:id).each do |a|
  puts [a.id, a.uid, a.name, (a.confidential ? 'confidential' : 'public'),
        "tokens_30d=#{recent.fetch(a.id, 0)}", a.redirect_uri.split.join(' ')].join(' | ')
end; nil
```

Check three things in the output:

1. **The Swagger record** (uid `27fe637fbd8c…`). If any of its redirect URIs is
   `http://` with a host other than `localhost`, step 4 will refuse to run.
   Change that URI to `https://` (or remove it) before deploying.
2. **No existing record already uses uid `memverse-pwa`.** If one does, the
   deploy migration will repurpose it as the public PWA client.
3. **Record the mobile app UIDs** (high `tokens_30d`). They are needed to replace
   the password-grant denylist with an allowlist later.

## 2. Back up the database

```bash
mysqldump -u <user> -p memverse_production > backup_$(date +%Y%m%d).sql
```

## 3. Deploy

```bash
cap production deploy
```

This installs one new gem (`rack-cors`, pure Ruby) and runs two migrations:

- `20260916225500_enable_pkce` adds two nullable columns to `oauth_access_grants`.
- `20260916231500_register_pwa_oauth_application` creates the public `memverse-pwa` client.

If a migration fails, Capistrano aborts before switching the `current` symlink,
and the old release keeps serving.

## 4. Reconcile the Swagger UI client

Run this immediately after the deploy:

```bash
cd /home/avitus/memverse.com/current && RAILS_ENV=production bundle exec rake oauth:ensure_swagger_application
```

It makes the Swagger client public and adds `https://www.memverse.com/api/o2c.html`
as a redirect URI. It only adds: existing redirect URIs, scopes, and the secret
are kept, and Doorkeeper still verifies a secret that a caller supplies, so
nothing already using this client loses access.

Until this runs, Swagger's **Authorize** button fails. A confidential client
fails the token exchange with `401 invalid_client`, and an unregistered callback
fails authorization with `400`. Only the API docs are affected.

If the task aborts, it prints the invalid URI and changes nothing. Fix that URI
and re-run the task.

## 5. Smoke tests

These are read-only and can be run from any machine.

```bash
# New code is live: Swagger advertises the authorization code flow.
curl -s https://www.memverse.com/apidocs.json \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["securityDefinitions"]["oauth2"]["flow"])'
# expect: accessCode

# CORS answers the PWA origin.
curl -s -o /dev/null -D - -X OPTIONS https://www.memverse.com/api/v1/me \
  -H 'Origin: https://avitus.github.io' -H 'Access-Control-Request-Method: GET' \
  | grep -i '^access-control-allow-origin'
# expect: access-control-allow-origin: https://avitus.github.io

# CORS refuses an unlisted origin.
curl -s -o /dev/null -D - -X OPTIONS https://www.memverse.com/api/v1/me \
  -H 'Origin: https://example.com' -H 'Access-Control-Request-Method: GET' \
  | grep -ci '^access-control-allow-origin'
# expect: 0
```

Then check these by hand:

- **iOS and Android:** sign out, then sign back in. Both must succeed. A failure
  here is the one regression that matters. Roll back (step 7) if it happens.
- **Swagger:** open <https://www.memverse.com/api/>, click **Authorize**, finish
  the flow, and call `GET /api/v1/me`.
- **Token lifetimes:** after the mobile sign-ins, run this in a console:

  ```ruby
  Doorkeeper::AccessToken.where('created_at > ?', 1.hour.ago).group(:application_id, :expires_in).count
  ```

  The mobile app IDs should show only `nil` (non-expiring). The PWA and Swagger
  should show `7200`.

## 6. Monitor

For the next 24 hours, watch Sentry (org `veetle`, project `memverse`) for 5xx
errors on `/oauth/token` and `/oauth/authorize`, and for exceptions raised from
Doorkeeper.

## 7. Rollback

```bash
cap production deploy:rollback
```

No down-migrations are needed. Under the old code:

- The new `oauth_access_grants` columns are ignored.
- The `memverse-pwa` record is ignored. Delete it if the rollback is permanent.
- The reconciled Swagger client still works, because the implicit flow does not
  need a secret.
- Tokens issued after the deploy stay valid. The PWA's refresh tokens stop
  working, because the old configuration disables refresh, so PWA users sign in
  again.

## Known follow-ups

- **Tighten the password grant.** It is currently allowed for every client except
  `memverse-pwa`. Replace this denylist with an allowlist of the mobile UIDs from
  step 1.3. The CodeRabbit thread on PR #397 is left open to track this.
- **Remove the shim.** Once both mobile apps ship authorization code + PKCE
  (anirac-tech/memverse_project#75), remove `resource_owner_from_credentials`,
  `password` from `grant_flows`, `allow_grant_flow_for_client`, and
  `custom_access_token_expires_in`.
