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
- Native iOS client: `ios/` (Xcode project, SwiftUI). Working rules are in `ios/AGENTS.md`. Setup and the API contract are in `documentation/ios/`.

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

Run the checks for the domains you changed. A required check that fails blocks completion. Do not claim a suite passed unless that command was run.

| Change | Required verification |
| --- | --- |
| Swift, the Xcode project, or iOS settings only | The iOS build and the affected client tests. Commands and destinations are in `ios/AGENTS.md`. Canonical setup is `documentation/ios/README.md`. |
| Rails or web code | RSpec, then Vitest, then Cucumber, in that order. |
| API, serialization, authentication, review logic, or a shared contract | The Rails order above, plus the iOS contract tests and a safe-backend integration when one can run. |
| CI, build tooling, or dependencies | Validation for every affected domain. |
| Documentation only | Confirm the docs match the code. |

A Swift-only change does not require the Rails or JavaScript suites. A Rails or web change still runs all three, in order. Do not skip, reorder, or partially run that sequence unless explicitly instructed.

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

- Run all JS tests: `npm run test:run` (`npm test` starts Vitest in watch mode and does not exit)
- Watch mode: `npm test`
- Coverage: `npm run test:coverage`
- Single test file: `npm run test:run -- path/to/file.test.js`

### Required order for Rails and web changes

1. RSpec
2. Vitest
3. Cucumber

iOS commands, when that domain changed, are in `ios/AGENTS.md`. Run them in addition to this sequence when the change also touches the API, authentication, or review behavior.

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

- Never claim task completion without the checks required for the changed domains passing
- Never ignore failing tests
- Never add TODOs instead of fixes
- Never invent behavior not present in code
- When unsure, ask before changing behavior

---

End of AGENTS.md
