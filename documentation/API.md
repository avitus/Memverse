# API v1

The JSON API used by the iOS app, the Flutter/Android app and the PWA. OAuth 2 via Doorkeeper,
Rails API controllers under `app/controllers/api/v1/`, Swagger documentation generated from
`swagger-blocks` DSL in each controller. Merged in October 2026 from
`API_AUTHENTICATION_VERIFICATION.md`, `API_TESTING_REPORT.md` and the follow-ups in
`OAUTH_PKCE_DEPLOY_RUNBOOK.md` (all in git history).

## Authentication (Doorkeeper, `config/initializers/doorkeeper.rb`)

- Endpoints: `/oauth/authorize`, `/oauth/token`, `/oauth/revoke`; applications are managed at
  `/oauth/applications` (admins only).
- **Authorization code with PKCE** is the supported flow for new clients: `force_pkce` with
  `pkce_code_challenge_methods %w[S256]`. Public (non-confidential) applications send their `uid` as
  `client_id` and no secret. Access tokens expire after **2 hours**; **refresh tokens are issued and
  rotate on use** (`use_refresh_token`).
- **Password grant (legacy, kept deliberately).** `grant_flows %w[authorization_code password]` and a
  `resource_owner_from_credentials` block exist only for the shipped iOS and Flutter clients, which
  sign in with username + password and ignore token expiry (their password-grant tokens never expire:
  `custom_access_token_expires_in`). `allow_grant_flow_for_client` refuses the password grant to the
  PWA (`PwaOauthApplication::UID`, `memverse-pwa`) but allows it for every other client. Changing
  `grant_flows` breaks mobile login.
- Scopes: default `public`; optional `read`, `write`, `admin`. Every protected action calls
  `doorkeeper_authorize! :admin, :write, :read, :public`, so any scope grants access; scope
  restriction per endpoint is a future change.
- `skip_authorization` returns `true`: users are not shown a consent screen (all apps are trusted).
- `force_ssl_in_redirect_uri` except for `localhost`.
- The authorization endpoint uses the Devise session; a signed-out user is sent through the normal
  login first.

### Registered public clients

| Application | `uid` | Redirect URIs | Maintained by |
|---|---|---|---|
| Memverse PWA | `memverse-pwa` | `https://avitus.github.io/Memverse/authentication/login-callback`, `http://localhost:5078/authentication/login-callback` (override with `MEMVERSE_PWA_REDIRECT_URIS`) | `rake oauth:ensure_pwa_application` (idempotent; also run by a migration) |
| Swagger UI | client id in `public/api/index.html` | `/api/o2c.html` | `rake oauth:ensure_swagger_application` |

### CORS (`config/initializers/cors.rb`)

Browser clients may call `/oauth/token`, `/oauth/revoke` and `/api/v1/*` cross-origin from the
origins in `MEMVERSE_CORS_ALLOWED_ORIGINS` (comma-separated, exact origins, no paths or trailing
slashes). The default list is `https://avitus.github.io`, `http://localhost:5078`,
`http://localhost:5000`, `https://localhost:5001`; setting the variable replaces it. Allowed headers
are `Authorization` and `Content-Type`.

### Getting a token for manual testing

```ruby
# bundle exec rails console
user = User.find_by(email: 'you@example.com')
app  = Doorkeeper::Application.create!(name: 'Console test', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                       scopes: 'public read write', confidential: false)
token = Doorkeeper::AccessToken.create!(application_id: app.id, resource_owner_id: user.id,
                                        scopes: 'public read write')
puts token.token
```

```bash
curl -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" https://www.memverse.com/api/v1/me
```

Tokens go in the `Authorization` header, never in the query string.

## Endpoints (`config/routes.rb`, `namespace :api { namespace :v1 }`)

All routes require a bearer token unless marked **open**.

| Method and path | Controller#action | Notes |
|---|---|---|
| `GET /api/v1/me` | `credentials#me` | current user |
| `POST /api/v1/users` | `users#create` | **open**: registration |
| `GET /api/v1/users/:id` | `users#show` | |
| `PATCH/PUT /api/v1/users/:id` | `users#update` | |
| `DELETE /api/v1/users/:id` | `users#destroy` | own account only |
| `POST /api/v1/password_resets` | `password_resets#create` | **open**: sends the reset email |
| `PUT /api/v1/password_resets` | `password_resets#update` | **open**: sets the new password with the token |
| `GET /api/v1/memverses` | `memverses#index` | paginated, sortable (`sanitize_sort_param` whitelist) |
| `GET /api/v1/memverses/:id` | `memverses#show` | |
| `POST /api/v1/memverses` | `memverses#create` | |
| `PATCH/PUT /api/v1/memverses/:id` | `memverses#update` | records a review and applies the spaced-repetition update |
| `DELETE /api/v1/memverses/:id` | `memverses#destroy` | 204 |
| `GET /api/v1/verses/:id` | `verses#show` | |
| `GET /api/v1/verses/lookup` | `verses#lookup` | by reference and translation |
| `GET /api/v1/verses/chapter` | `verses#chapter` | whole chapter |
| `GET /api/v1/verses/search` | `verses#search` | |
| `GET /api/v1/passages` | `passages#index` | |
| `GET /api/v1/passages/due` | `passages#due` | passages due for review |
| `GET /api/v1/passages/:id` | `passages#show` | |
| `DELETE /api/v1/passages/:id` | `passages#destroy` | 204 |
| `GET /api/v1/passages/:passage_id/memverses` | `memverses#index` (nested) | |
| `GET /api/v1/quizzes` | `quizzes#index` | |
| `GET /api/v1/quizzes/upcoming` | `quizzes#upcoming` | next knowledge quiz |
| `GET /api/v1/quizzes/:id` | `quizzes#show` | |
| `GET /api/v1/translations` | `translations#index` | |
| `GET /api/v1/final_verses` | `final_verses#index` | last verse number of every chapter |
| `GET /api/v1/progress_reports` | `progress_reports#index` | |
| `POST /api/v1/record_score` | `live_quiz#record_score` | live-quiz answer; 204 |

`resources :verses`, `:memverses`, `:passages` and `:quizzes` are declared with all seven REST routes;
actions not implemented in the controller answer 404. The `POST /api/v1/record_score` parameters are
`usr_id`, `usr_name`, `usr_login`, `question_id`, `question_num`, `score` (0–10) and optional
`quiz_id` (default 1); see [QUIZ_SYSTEM.md](./QUIZ_SYSTEM.md).

## Response envelope (`app/controllers/concerns/api_response_helpers.rb`)

Responses keep the shape of the original RocketPants API so existing clients keep working.
Controllers call `expose(data, options)`:

```json
{ "response": { "id": 1, "name": "..." } }
```

```json
{
  "response": [ { "id": 1 }, { "id": 2 } ],
  "count": 2, "page": 1, "page_count": 1, "per_page": 25,
  "pagination": { "pages": 1, "count": 2 }
}
```

Plain arrays (no Kaminari pagination) carry `response` and `count` only. Errors use
`error!(status, metadata: {...})`, which renders the status name plus any metadata keys at the root:

```json
{ "error": "not_found" }
```

Status codes in use: 200, 201, 204 (deletes and `record_score`), 400, 401 (missing or invalid token),
404.

## Swagger

- Spec: `GET /apidocs.json` (`ApidocsController`, assembled from the `swagger_path` / `swagger_schema`
  blocks in each API controller and model).
- UI: `/api/index.html` (static `public/api/`, swagger-ui 2.1.2-M2). Its "Authorize" button runs the
  PKCE flow with the Swagger OAuth application and the `/api/o2c.html` callback.
- Rules (also in `CLAUDE.md`): schemas must match `as_json`, responses and parameters must match the
  controllers, update both in the same change, run `./test_swagger_ui.sh` against a local server, and
  avoid `allOf`, `x-nullable`, `externalDocs` and mixed types, which this UI version cannot render.

## Tests

`spec/controllers/api/v1/` covers every controller with Doorkeeper token doubles. Run the suites
after any API change (`bundle exec rspec spec/controllers/api/v1/` for a quick loop).

## Follow-ups

- **Tighten the password grant to an allowlist.** Today it is allowed for every client except
  `memverse-pwa`. Replace the denylist in `allow_grant_flow_for_client` with the UIDs of the two
  mobile applications. Tracked in the open CodeRabbit thread on PR #397.
- **Remove the password-grant shim** once both mobile apps ship authorization code + PKCE
  (anirac-tech/memverse_project#75): delete `resource_owner_from_credentials`, `password` from
  `grant_flows`, `allow_grant_flow_for_client` and `custom_access_token_expires_in` in
  `config/initializers/doorkeeper.rb`.
- Per-endpoint scope enforcement and per-token rate limiting remain unimplemented.
