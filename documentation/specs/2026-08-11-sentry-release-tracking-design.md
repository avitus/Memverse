# Sentry Release Tracking — Design Spec

**Date**: 2026-08-11
**Status**: Approved
**Branch**: `chore/sentry-sdk-migration`

## Problem

Sentry cannot tell us which deploy introduced an error. The `memverse` project in
Sentry has no release records, so errors are not correlated with deployed git
revisions. With deploys that batch months of changes (e.g. the pending Rails 7.2 +
Devise 5 + jwt 3 deploy), attribution matters.

Two underlying causes:

1. The app uses **`sentry-raven` 3.1.2**, the legacy Sentry SDK, end-of-life since
   2021. Its Rails 7.x compatibility is unverified.
2. No release value reaches Sentry. Additionally, Sentry shows **zero error events
   in the last 90 days** — production is either genuinely error-free or event
   delivery is silently broken. The migration settles this either way.

## Goal

Every production error reaching Sentry is tagged with the git SHA that Capistrano
deployed, so errors correlate directly to deploys.

## Decisions (made during brainstorming)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SDK scope | Migrate `sentry-raven` → `sentry-ruby` + `sentry-rails` + `sentry-sidekiq` | Supported SDK with first-class release detection; retires an EOL dependency; consistent with modernization roadmap |
| Release registration | Runtime tagging only (no deploy-time API call) | Reading Capistrano's `REVISION` at boot fully achieves error↔deploy correlation with zero new secrets or deploy steps |

## Design

### 1. Gemfile

- Remove `gem "sentry-raven"`.
- Add `gem "sentry-ruby"`, `gem "sentry-rails"`, `gem "sentry-sidekiq"`.

`sentry-sidekiq` is included because Sidekiq runs core background work (reminder,
quiz, and metrics workers) and the raven setup never captured worker errors.

### 2. Initializer rewrite (`config/initializers/sentry.rb`)

```ruby
# Error tracking
Sentry.init do |config|
  config.dsn = "https://a1106f25de724396a866c6ab9386b11b@sentry.io/299442"
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger]
  # send_default_pii stays false (default): request bodies / cookies / IPs are
  # not sent. Rails filter_parameters are applied to what is sent.
end
```

Behavior parity with the raven config:

- **Production-only**: `config.enabled_environments = %w[production]` replaces
  raven's `config.environments`. No events, ever, from development or test.
- **Parameter sanitization**: raven used `config.sanitize_fields` built from
  `Rails.application.config.filter_parameters`. sentry-rails applies Rails
  parameter filtering to request data automatically; implementation must verify
  this (and add explicit filtering config if the installed SDK version does not).
- The DSN's legacy secret-key portion is dropped (modern DSN format); the DSN
  stays in the initializer as today. Moving it to credentials is out of scope.

### 3. Release detection (the actual feature)

No explicit `config.release`. The modern SDK detects the release in this order:

1. `SENTRY_RELEASE` environment variable
2. Current git SHA (wins in development checkouts; Capistrano release
   directories contain no `.git`, so this is skipped in production)
3. Capistrano `REVISION` file at the project root

Capistrano already writes `REVISION` (full 40-char SHA) into every release
directory — production revision `f370078e9f33…` was confirmed present on
`www.memverse.com` at `current/REVISION`. So production release tagging requires
**no deploy-side changes**. Sentry creates the release record when the first
tagged event arrives.

Verification: `Sentry.configuration.release` from a **production** console. Outside `enabled_environments` the SDK skips release detection entirely, so development/test consoles print `nil` — expected, not a failure.

### 4. Call-site migration

`app/lib/bible_gateway.rb:65`:

```ruby
# before
Raven.tags_context(service: 'bible_gateway', http_status: ...) if defined?(Raven)
# after
Sentry.set_tags(service: 'bible_gateway', http_status: ...) if defined?(Sentry)
```

This is the only `Raven.` call site outside the initializer (verified by grep;
no spec/feature references exist).

## Error handling

- Missing `REVISION` (local dev): detection falls back to git SHA, then nil.
  Never raises.
- `Sentry.init` with `enabled_environments` not matching current env: SDK is
  loaded but sends nothing — `Sentry.set_tags` and friends remain safe no-ops.

## Testing

- New spec (e.g. `spec/initializers/sentry_spec.rb`) asserting: DSN configured,
  `enabled_environments == ["production"]`, `send_default_pii` false.
- Full suites must pass per project policy: RSpec, Vitest, Cucumber.

## Post-deploy verification (manual, one-time)

After the next production deploy:

1. `Sentry.capture_message("release tracking test")` from the production Rails
   console.
2. Confirm the event appears in Sentry tagged with the deployed SHA and that a
   release record now exists.

This also settles whether the 90-day event silence was health or breakage.

## Out of scope

- Deploy-time Sentry Releases API notification / deploy markers (revisit if
  "resolved in next release" workflows are wanted).
- Performance tracing / profiling (`traces_sample_rate` stays unset).
- Moving the DSN into Rails credentials.
- New Relic (separate monitoring stack, untouched).
