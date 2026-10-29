# Error monitoring (Sentry)

Memverse reports exceptions to Sentry (organisation `veetle`) with the `sentry-ruby`, `sentry-rails`
and `sentry-sidekiq` gems at 6.7.0. The legacy `sentry-raven` SDK was replaced in August 2026; see
`documentation/plans/2026-08-11-sentry-release-tracking.md`.

## Configuration

Everything is in `config/initializers/sentry.rb`:

| Setting | Value | Effect |
|---|---|---|
| `dsn` | hard-coded project DSN (`sentry.io/299442`) | no credential needed; the DSN is public by design |
| `enabled_environments` | `%w[production]` | nothing is sent from development, test or CI |
| `breadcrumbs_logger` | `[:active_support_logger]` | Rails log lines become breadcrumbs on each event |
| `before_send` | `SentryEmailScrubber` | every event is scrubbed before it leaves the process (below) |
| `release` | not set | auto-detected by the SDK: `SENTRY_RELEASE`, then the local git SHA, then Capistrano's `REVISION` file. Capistrano release directories have no `.git`, so production events carry the deployed commit from `REVISION`; outside production `Sentry.configuration.release` is `nil`, which is expected |

`sentry-rails` captures unhandled controller exceptions and `sentry-sidekiq` captures failed jobs
automatically. The Sidekiq `error_handlers` block in `config/initializers/sidekiq.rb` only logs
(its `Sentry.capture_exception` line is commented out), so job errors reach Sentry once, via the
sentry-sidekiq middleware.

## Email scrubbing

`lib/sentry_email_scrubber.rb` is the `before_send` hook. `send_default_pii` is off, but addresses
still reach events through exception messages (Postmark names the recipient), breadcrumbs (SQL with
literal values, unfiltered params) and headers such as `Referer`. The scrubber replaces anything
matching its permissive email pattern (including `%40`-encoded `@`) with `[email redacted]` in the
event's `message`, `transaction`, `extra`, `contexts`, `tags` and `user`, in the request's `url`,
`query_string`, `data`, `cookies`, `headers` and `env`, in every exception value, and in every
breadcrumb message and data hash. Strings with invalid encoding are `scrub`bed first so `gsub` cannot
raise and drop the event.

## Explicit captures in application code

- `SendReminders` (`app/workers/send_reminders.rb`): `Sentry.capture_message(..., level: :warning)`
  when Postmark raises `InvalidEmailRequestError` for a progression email (a malformed message raises
  the same error as a malformed address). Only the error code and user id are attached.
- `User#send_devise_notification` (`app/models/user.rb`): the same warning for Devise mail.
- `AttackProtectionMiddleware` (`app/middleware/attack_protection_middleware.rb`) rescues
  `ActionDispatch::RemoteIp::IpSpoofAttackError`, logs it and answers 403, so IP-spoofing probes do not
  create Sentry issues. See [ATTACK_PROTECTION.md](./ATTACK_PROTECTION.md).

## Day to day

- Issues: the `veetle` organisation on sentry.io; filter by the `release` tag to compare deploys and by
  `server_name` (`martial-eagle` since the 2026-10-17 cutover).
- After a deploy, watch Sentry for new issue types alongside `shared/log/production.log` and the
  Sidekiq logs (see [DEPLOYMENT.md](./DEPLOYMENT.md)).
- New Relic APM is also configured (`config/newrelic.yml`) for performance, not errors.

## Verifying changes

Run the suites; `spec/lib/sentry_email_scrubber_spec.rb` covers the scrubber. Sentry itself is
disabled in test, so nothing needs network access.
