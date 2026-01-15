# AGENTS.md

This file provides guidance for **agentic coding tools** (Codex, Claude Code, Cursor, Copilot, etc.) operating in this repository. Follow these rules exactly unless overridden by a higher‑priority system or user instruction.

Scope: **entire repository**

---

## Project Overview

- Ruby on Rails **7.1.x** application
- Ruby **3.2.6**
- MySQL (primary DB), Redis (Sidekiq + ephemeral data)
- Frontend: jQuery 1.12, SASS, CoffeeScript
- Testing: **RSpec**, **Cucumber**, **Vitest**
- Architecture: traditional MVC with several mounted engines (Thredded, Bloggity, RailsAdmin)

---

## Core Commands

### Application

- Start full app: `./bin/dev`
- Stop full app: `./bin/shutdown`
- App status: `./bin/status`
- Rails server only: `bundle exec rails server`
- Rails console: `bundle exec rails console`

### Database

- Migrate: `bundle exec rake db:migrate`
- Rollback: `bundle exec rake db:rollback`
- Schema load (test): `bundle exec rake db:schema:load RAILS_ENV=test`

---

## Testing (MANDATORY)

**All changes must keep 100% tests passing. Never claim completion otherwise.**

### Ruby (RSpec)

- Run all unit tests: `bundle exec rspec`
- Run single file: `bundle exec rspec spec/models/user_spec.rb`
- Run single example (by line): `bundle exec rspec spec/models/user_spec.rb:42`
- Run by description: `bundle exec rspec -e "validates email"`

### Integration (Cucumber)

- Run all features: `bundle exec cucumber`
- Run single feature: `bundle exec cucumber features/login.feature`
- Run scenario (line): `bundle exec cucumber features/login.feature:17`

### JavaScript (Vitest)

- Run all JS tests: `npm test`
- Watch mode: `npm run test:run`
- Coverage: `npm run test:coverage`
- Single test file: `npm test app/javascript/foo.test.js`

### Required Test Order (when asked to run tests)

1. RSpec
2. Vitest
3. Cucumber

Never skip, reorder, or partially run tests unless explicitly instructed.

---

## Linting & Formatting

- Ruby style: **RuboCop conventions** (implicit; do not reformat unrelated code)
- JavaScript: project‑local ESLint/Vitest defaults
- CSS/SASS: see `documentation/STYLE_GUIDE.md`

Do **not** introduce new linters, formatters, or config files unless requested.

---

## Code Style Guidelines

### General

- Prefer **small, focused changes**
- Fix root causes, not surface symptoms
- Do not refactor unrelated code
- Match existing patterns exactly

### Naming

- Ruby classes: `CamelCase`
- Ruby methods/vars: `snake_case`
- JS variables/functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Database columns: `snake_case`

### Imports / Requires

- Ruby: use `require_relative` only when necessary
- Rails autoloading is preferred
- JavaScript: use existing import style (ESM where present)

### Types & Data

- Ruby is dynamically typed; **do not add Sorbet/RBS**
- Use `nil` checks explicitly
- Avoid monkey‑patching core classes

### Error Handling

- Prefer explicit guards (`return if`, `raise ArgumentError`)
- Never rescue broad `StandardError` without re‑raising or logging
- Controllers: handle errors with proper HTTP status codes
- Background jobs: ensure retries are safe and idempotent

### ActiveRecord

- Avoid N+1 queries; use `includes`
- Prefer scopes over class methods
- Validate at the model level, not controllers
- Never interpolate user input into SQL

### Controllers

- Keep thin: delegate logic to models/services
- Strong params required
- Never use `send`/`public_send` without whitelisting

### Views

- Never use `html_safe` unless absolutely required
- Prefer `sanitize()` for user content
- No business logic in templates

### JavaScript

- Prefer existing jQuery patterns
- Avoid introducing modern frameworks
- Keep logic modular and testable

---

## API & Swagger Rules (CRITICAL)

When modifying API endpoints:

- Update controller behavior
- Update Swagger schemas **in the same change**
- Ensure response JSON matches Swagger exactly
- Avoid unsupported Swagger features (allOf, mixed types, etc.)
- Validate with `test_swagger_ui.sh` when applicable

---

## Background Jobs (Sidekiq)

- Jobs live in `app/workers/`
- Must be idempotent
- Never rely on Redis for persistent data
- Handle retries safely

---

## Files You Must Not Touch

- `config/master.key`
- Encrypted credentials blobs
- Production secrets or tokens

---

## Documentation

- All docs belong in `documentation/`
- Do not create new docs unless requested
- Update existing docs only if behavior changes

---

## Git Rules

- Do NOT commit unless explicitly asked
- Do NOT amend commits unless explicitly asked
- Do NOT push unless explicitly asked

---

## Agent Behavior Rules

- Never claim task completion without 100% passing tests
- Never ignore failing tests
- Never add TODOs instead of fixes
- Never invent behavior not present in code
- When unsure, ask before changing behavior

---

End of AGENTS.md
