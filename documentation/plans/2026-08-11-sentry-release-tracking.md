# Sentry Release Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the EOL `sentry-raven` SDK with `sentry-ruby`/`sentry-rails`/`sentry-sidekiq` so every production error is tagged with the deployed git SHA (read from Capistrano's `REVISION` file by the SDK's built-in release detection).

**Architecture:** Three self-contained changes: (1) swap the gems and rewrite `config/initializers/sentry.rb` as `Sentry.init` with behavior parity (production-only, no PII); (2) migrate the single legacy `Raven.tags_context` call site in `BibleGateway`; (3) verify with the full test suites. No deploy-side changes: Capistrano already writes `REVISION`, which the modern SDK detects natively.

**Tech Stack:** Rails 7.2.3.1, Ruby 3.2.6, RSpec, sentry-ruby/sentry-rails/sentry-sidekiq (6.7.0, latest from RubyGems at implementation time).

**Spec:** `documentation/specs/2026-08-11-sentry-release-tracking-design.md`

## Global Constraints

- Branch: `chore/sentry-sdk-migration` (already created; spec committed on it).
- 100% of tests must pass — RSpec, Vitest, AND Cucumber — before claiming any task complete (project policy, CLAUDE.md).
- RSpec and Cucumber share the test database: run them **serially, never concurrently**.
- Sentry must send events **only** from the `production` environment (parity with the old raven config).
- No PII in events: `send_default_pii` stays `false` (SDK default — do not set it to true).
- DSN (modern format, no secret key): `https://a1106f25de724396a866c6ab9386b11b@sentry.io/299442`
- Do NOT set `config.release` explicitly — the SDK's built-in detection (SENTRY_RELEASE env → git SHA → Capistrano `REVISION` file) is the feature under delivery.
- Do NOT stage `node_modules/` churn in any commit (only `package.json` + `package-lock.json` would ever be committed for npm changes; this plan makes no npm changes).
- Commit messages end with: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`

---

### Task 1: Swap SDK gems and rewrite the Sentry initializer

**Files:**
- Modify: `Gemfile:116` (the `gem "sentry-raven"` line)
- Modify: `Gemfile.lock` (via `bundle install` — never by hand)
- Rewrite: `config/initializers/sentry.rb`
- Create: `spec/initializers/sentry_spec.rb`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: a booted app where the global `Sentry` module is initialized in every environment (sending gated to production). Task 2 relies on `Sentry.set_tags(hash)` being callable and on `defined?(Sentry)` being truthy.

- [ ] **Step 1: Write the failing spec**

Create `spec/initializers/sentry_spec.rb` (new directory `spec/initializers/` — precedent: `spec/middleware/`):

```ruby
require 'rails_helper'

RSpec.describe 'Sentry configuration' do
  let(:config) { Sentry.configuration }

  it 'is initialized' do
    expect(Sentry.initialized?).to be true
  end

  it 'sends events only from production' do
    expect(config.enabled_environments).to eq(['production'])
  end

  it 'points at the memverse Sentry project' do
    expect(config.dsn.public_key).to eq('a1106f25de724396a866c6ab9386b11b')
    expect(config.dsn.project_id.to_s).to eq('299442')
    expect(config.dsn.host).to eq('sentry.io')
  end

  it 'does not send personally identifiable information' do
    expect(config.send_default_pii).to be false
  end

  it 'records ActiveSupport breadcrumbs' do
    expect(config.breadcrumbs_logger).to include(:active_support_logger)
  end
end
```

- [ ] **Step 2: Run the spec to verify it fails**

Run: `bundle exec rspec spec/initializers/sentry_spec.rb`
Expected: FAIL — `NameError: uninitialized constant Sentry` (the raven gem defines `Raven`, not `Sentry`).

- [ ] **Step 3: Swap the gems**

In `Gemfile`, replace the single line (currently line 116):

```ruby
gem "sentry-raven"                                                             # Error tracking
```

with:

```ruby
gem "sentry-ruby"                                                              # Error tracking
gem "sentry-rails"                                                             # Error tracking - Rails integration
gem "sentry-sidekiq"                                                           # Error tracking - Sidekiq worker errors
```

Then run: `bundle install`
Expected: resolves cleanly; `sentry-raven` removed from `Gemfile.lock`, three `sentry-*` gems (same version, 6.7.0) added. `faraday` remains in the lockfile (other gems still need it) — that is fine.

- [ ] **Step 4: Rewrite the initializer**

Replace the entire contents of `config/initializers/sentry.rb` with:

```ruby
# Error tracking.
# Release is intentionally NOT set here: sentry-ruby auto-detects it from
# SENTRY_RELEASE, then Capistrano's REVISION file, then the local git SHA —
# so production events are tagged with the exact deployed commit.
Sentry.init do |config|
  config.dsn = 'https://a1106f25de724396a866c6ab9386b11b@sentry.io/299442'
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger]
end
```

- [ ] **Step 5: Run the spec to verify it passes**

Run: `bundle exec rspec spec/initializers/sentry_spec.rb`
Expected: 5 examples, 0 failures.

- [ ] **Step 6: Verify no-PII parity with the old sanitize_fields behavior**

The old raven config sent sanitized request bodies; the modern SDK must not send bodies/cookies at all with `send_default_pii = false`. Verify against the installed gem source:

Run: `grep -n -A6 "send_default_pii" "$(bundle show sentry-ruby)/lib/sentry/interfaces/request.rb"`
Expected: request `data` (body) and `cookies` are populated **only** inside the `send_default_pii` branch.

Decision rule: if (and only if) the installed version populates request data unconditionally, add this inside the `Sentry.init` block and re-run Step 5:

```ruby
  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    event.request.data = filter.filter(event.request.data) if event.request&.data.is_a?(Hash)
    event
  end
```

- [ ] **Step 7: Smoke-check release detection wiring**

Run: `bundle exec rails runner "puts Sentry.configuration.release.inspect"`
Expected: prints `nil` — on sentry-ruby 6.x, release detection only runs where sending is allowed (production), so `nil` outside production is the correct result; an exception is a failure.

- [ ] **Step 8: Commit**

```bash
git add Gemfile Gemfile.lock config/initializers/sentry.rb spec/initializers/sentry_spec.rb
git commit -m "Replace EOL sentry-raven with sentry-ruby/rails/sidekiq for release tracking

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Migrate the BibleGateway Raven call site

**Files:**
- Modify: `app/lib/bible_gateway.rb:65`
- Modify: `spec/lib/bible_gateway_spec.rb`

**Interfaces:**
- Consumes: initialized `Sentry` module from Task 1 (`Sentry.set_tags(hash)`).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the failing test**

In `spec/lib/bible_gateway_spec.rb`, add inside `describe '#lookup'`:

```ruby
    it 'tags Sentry with service context on persistent HTTP failures' do
      io = double('io', status: ['503', 'Service Unavailable'])
      error = OpenURI::HTTPError.new('503 Service Unavailable', io)

      allow(URI).to receive(:open).and_raise(error)
      allow(gateway).to receive(:sleep) # skip retry backoff delays
      allow(Sentry).to receive(:set_tags)

      gateway.lookup('John 3:16')

      expect(Sentry).to have_received(:set_tags)
        .with(service: 'bible_gateway', http_status: '503')
    end
```

- [ ] **Step 2: Run the spec file to verify the new test fails**

Run: `bundle exec rspec spec/lib/bible_gateway_spec.rb`
Expected: 3 examples, 1 failure — the new test fails with "expected Sentry to have received set_tags" (the code still guards on `defined?(Raven)`, which is now false, so nothing is called).

- [ ] **Step 3: Migrate the call site**

In `app/lib/bible_gateway.rb`, replace line 65:

```ruby
      Raven.tags_context(service: 'bible_gateway', http_status: e.io&.status&.first) if defined?(Raven)
```

with:

```ruby
      Sentry.set_tags(service: 'bible_gateway', http_status: e.io&.status&.first) if defined?(Sentry)
```

- [ ] **Step 4: Run the spec file to verify all pass**

Run: `bundle exec rspec spec/lib/bible_gateway_spec.rb`
Expected: 3 examples, 0 failures.

- [ ] **Step 5: Verify no Raven references remain in app code**

Run: `grep -rn "Raven" app/ lib/ config/ --include="*.rb" --include="*.rake"`
Expected: no output. (References in `tmp/`, `documentation/`, and specs' prose descriptions are acceptable; `spec/` should also come back clean of `Raven.` API calls.)

- [ ] **Step 6: Commit**

```bash
git add app/lib/bible_gateway.rb spec/lib/bible_gateway_spec.rb
git commit -m "Migrate BibleGateway error tagging from Raven to Sentry API

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Full-suite verification

**Files:** none created or modified (verification only).

**Interfaces:**
- Consumes: the completed work of Tasks 1–2.
- Produces: green suites; the branch is ready for PR/merge.

- [ ] **Step 1: Run RSpec (full)**

Run: `bundle exec rspec`
Expected: 0 failures (baseline: ~1227 examples + 6 new = ~1233, 25 pending). Any failure must be fixed before proceeding — never proceed with failing tests.

- [ ] **Step 2: Run Vitest**

Run: `npm run test:run`
Expected: 409 tests passing, 0 failures (JS is untouched by this change).

- [ ] **Step 3: Run Cucumber (after RSpec finishes — shared test DB, never concurrent)**

Run: `bundle exec cucumber features`
Expected: 72 scenarios, 0 failures.

- [ ] **Step 4: Summarize results in a table** (project policy) and confirm working tree is clean apart from `.claude/settings.local.json`.

---

## Post-deploy verification (manual, one-time — not part of this branch)

After the next production deploy (per spec §Post-deploy verification):

1. On the server: `bundle exec rails console` then `Sentry.capture_message("release tracking test")`.
2. In Sentry (veetle/memverse): confirm the event arrived tagged with the deployed 40-char SHA and that a release record now exists.
3. This also settles whether the 90-day event silence was app health or broken raven delivery.
