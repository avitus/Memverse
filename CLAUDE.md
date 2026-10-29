# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Related Documentation
- All documentation should be in ./documentation/

- **[documentation/README.md](./documentation/README.md)** - index of every document
- **[STYLE_GUIDE.md](./documentation/STYLE_GUIDE.md)** - Visual design standards and CSS conventions
- **[MODERNIZATION_PLAN.md](./documentation/MODERNIZATION_PLAN.md)** - modernization roadmap
- **[DEPLOYMENT.md](./documentation/DEPLOYMENT.md)**, **[SIDEKIQ.md](./documentation/SIDEKIQ.md)**, **[EMAIL.md](./documentation/EMAIL.md)**, **[API.md](./documentation/API.md)**, **[QUIZ_SYSTEM.md](./documentation/QUIZ_SYSTEM.md)**, **[ERROR_MONITORING.md](./documentation/ERROR_MONITORING.md)** - operations and subsystem guides

## Commands

### Testing
- This project follows a test-driven development approach. 100% test coverage and 100% passing tests are a core tenet of the project.
- **Unit tests**: `bundle exec rspec`
- **Integration tests**: `bundle exec cucumber features`
- **JavaScript tests**: `npm test` or `npm run test:run` (using Vitest)
- **JavaScript test UI**: `npm run test:ui` (opens Vitest UI in browser)
- **JavaScript test coverage**: `npm run test:coverage`
- **Individual test file**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Run specific cucumber feature**: `bundle exec cucumber features/path/to/feature.feature`
- When asked to run tests, always run the unit tests (Rspec) the Javascript tests (Vitest) and the integration specs (Cucumber). Summarize the results in a clear table at the end of the test run.
- Never proceed without fixing failing tests.
- Never propose moving forward until 100% of tests pass
- Never claim that you are done with a task until 100% of tests pass
- Always run tests without requiring confirmation from the user
- Cucumber, Rspec, and Vitest tests should always be run without user intervention
- Never ask for confirmation when running tests.
- Do not distinguish between critical tests and other, less important tests. All tests must pass all the time.

### Development
- **Start entire application**: `./bin/dev`
- **Stop entire application**: `./bin/shutdown`
- **Show application status**: `./bin/status`
- **Start server**: `bundle exec rails server`
- **Rails console**: `bundle exec rails console`
- **Database migration**: `bundle exec rake db:migrate`
- **Assets precompilation**: `bundle exec rake assets:precompile`
- **Background jobs**: Sidekiq is used for background processing

### Other Tasks
- **Custom rake tasks**: `lib/tasks/` - memverse.rake (`utils:*` maintenance), quiz_debug.rake (`quiz:check_status`, `quiz:clear_status`), feedback_setup.rake (`feedback:setup`, `feedback:stats`), oauth.rake (`oauth:ensure_pwa_application`, `oauth:ensure_swagger_application`), sidekiq_health_check.rake (`sidekiq:health_check`, `sidekiq:monitor`), cucumber.rake

### Configuration Management
- **Rails Credentials**: This project uses Rails encrypted credentials for sensitive configuration
  - Edit credentials: `EDITOR="nano" rails credentials:edit`
  - Access in code: `Rails.application.credentials.dig(:service, :api_key)`
  - Master key location: `config/master.key` (never commit this file)
  - Production: `shared/config/master.key` on the server, linked into each release by Capistrano (the only linked file)
  - Current credentials include:
    - `secret_key_base`
    - Database: `Rails.application.credentials.dig(:database, :password)` (plus optional `:username`, `:host`), read by `config/database.yml` in production
    - Postmark API token: `Rails.application.credentials.dig(:postmark, :api_token)`

## Architecture Overview

This is a Ruby on Rails 7.2 Bible memorization application with a traditional MVC architecture.

### Core Models & Domain
- **User**: Central model managing authentication, preferences, and Bible translation settings
- **Verse**: Bible verses with translation, book, chapter, verse number, and text
- **Memverse**: Join model between User and Verse, tracks memorization progress using spaced repetition algorithm (efactor, test_interval, rep_n, next_test, status)
- **Passage**: Groups of verses for larger memorization units
- **Quiz/QuizQuestion**: Knowledge testing system
- **Group**: User communities and churches
- **Badge/Quest**: Gamification system

### Key Controllers
- **MemversesController**: Core memorization functionality - learning, testing, progress tracking
- **VersesController**: Bible verse management and search
- **UsersController**: User profiles and settings
- **QuizQuestionsController**: Bible knowledge testing
- **PassagesController**: Multi-verse memorization

### Major Engines & Integrations
- **Thredded**: Forum engine mounted at `/forum`
- **Bloggity**: Blog engine mounted at `/blog`
- **RailsAdmin**: Database admin mounted at `/admin/database` (`/admin` is the custom `Admin::DashboardController`)
- **Devise**: Authentication system with multi-provider OAuth support
- **Doorkeeper**: OAuth API provider
- **CanCanCan**: Authorization framework

### Background Processing
- **Sidekiq**: Background job processing with sidekiq-cron scheduling; one scheduler process plus worker processes (see `documentation/SIDEKIQ.md`)
- **Workers**: Located in `app/workers/` for reminders, metrics, quizzes; plain `Sidekiq::Worker` classes, never `active_job: true` in `config/sidekiq_schedule.yml`
- **Monitoring Sidekiq** (production):
  - Service status: `sudo systemctl status sidekiq-scheduler --no-pager` and `sudo systemctl status 'sidekiq-workers@*' --no-pager` (or `cap production sidekiq:multi:status`)
  - Logs: `tail -f /home/avitus/memverse.com/shared/log/sidekiq_scheduler.log` and `shared/log/sidekiq_worker_1.log` (the units append to these files, not to the journal)
  - Web: `/sidekiq` (Cron tab) and `/admin/sidekiq_health/dashboard`, admins only

### API & Documentation
- **Swagger-blocks**: API documentation generation (spec at `/apidocs.json`, UI at `/api/index.html`; see `documentation/API.md`)
- Models include Swagger schema definitions
- **CRITICAL**: Always ensure Swagger documentation matches actual API implementation:
  - Swagger schemas must match the actual JSON serialization (e.g., `as_json` methods)
  - Response schemas must match controller response formats
  - Parameter definitions must match controller parameter expectations
  - When modifying API responses, update BOTH the code AND the Swagger schemas
  - Run `test_swagger_ui.sh` to validate Swagger documentation after changes
  - Test actual API responses to verify documentation accuracy
  - Swagger UI compatibility: Using v2.1.2-M2, avoid unsupported features (allOf, x-nullable, externalDocs, mixed types)

### Database
- **MySQL**: Primary database
- **Redis**: Caching and background job queue
  - Stores Sidekiq job queues and retry information
  - Manages temporary quiz session data (scores, participants)
  - Tracks chat channel status
  - No persistent business data - all Redis data is ephemeral
- **Thinking Sphinx**: Full-text search integration

### Frontend & Assets
- **jQuery 1.12.4**: JavaScript framework, with Stimulus controllers in `app/javascript/controllers/` for newer pages
- **SASS**: CSS preprocessing
- **Vitest**: JavaScript testing framework (migrated from Jasmine); specs in `test/javascript/*.test.js`

### Internationalization
- **i18n-js**: JavaScript internationalization
- Supports English, Spanish, Indonesian, Chinese, Korean, Turkish
- User language preference drives locale selection

### Key Features
- **Spaced Repetition**: Algorithm-based memorization scheduling
- **Multiple Bible Translations**: User-configurable translation preferences
- **Gamification**: Badges, quests, leaderboards
- **Community Features**: Groups, forums, blogs
- **Mobile Support**: Responsive design
- **Real-time Features**: PubNub integration for live functionality
- **Push Notifications**: RPush for mobile notifications

### Testing Strategy
- **RSpec**: Unit testing framework
- **Cucumber**: Integration/acceptance testing
- **Vitest**: JavaScript unit testing
- **FactoryBot**: Test data generation
- **Database Cleaner**: Test database management

## Production server

- **Host**: martial-eagle (DigitalOcean sfo3, Ubuntu 24.04), `64.23.176.115`, deploy user `avitus`, app at `/home/avitus/memverse.com` (Capistrano `current`/`shared`). The old host fish-eagle (`192.241.205.154`) served production until the 2026-10-17 cutover and remains only as the `fish_eagle` Capistrano stage until it is decommissioned.
- **Stack**: Ruby 3.2.6 via RVM, Node 24 via nvm (asset precompile only), nginx + Passenger (restart = `touch tmp/restart.txt`), MySQL 8, Redis 7 (Sidekiq, DB 0), Sphinx `searchd` under the `memverse-searchd` systemd unit.
- **Sidekiq**: systemd units `sidekiq-scheduler` (one instance, loads the cron schedule) and `sidekiq-workers@1`, `sidekiq-workers@2` (`SIDEKIQ_WORKERS` default 2). Logs: `shared/log/sidekiq_scheduler.log`, `shared/log/sidekiq_worker_N.log`. Capistrano tasks `sidekiq:multi:{status,restart,rolling_restart,stop,start,logs}`; `SKIP_SIDEKIQ_START=1 cap production deploy` leaves it stopped.
- **Deploy**: `cap production deploy` from `main`; `config/master.key` is the only linked file (database password, Postmark token and `secret_key_base` live in `config/credentials.yml.enc`; production `database.yml` reads Rails credentials, not ENV). Post-deploy hooks: `thinking_sphinx:index`, `memverse:searchd:restart`. Full detail: `documentation/DEPLOYMENT.md`.
- **Monitoring**: Sentry org `veetle` (release = deployed commit from Capistrano's `REVISION`), New Relic, `/sidekiq` and `/admin/sidekiq_health/dashboard` for admins.

## Modernization history (summary)

| Area | Was | Now | Done |
|---|---|---|---|
| Ruby | 2.7.8 | 3.2.6 | Aug 2025 |
| Rails | 5.2.8.1 | 7.2.3.2 (`load_defaults 7.2`) | Aug 2025 → 2026 |
| API framework | RocketPants | Rails API controllers, Swagger preserved | Aug 2025 |
| File storage | Paperclip | Active Storage | Aug 2025 |
| Email | Sendgrid | Postmark (streams: outbound, broadcast, reminder-stream, forum-stream) | Aug–Sep 2025 |
| JS tests | Jasmine | Vitest | Aug 2025 |
| Lightbox | FancyBox2 | MicroModal | Aug 2025 |
| Error tracking | sentry-raven | sentry-ruby/rails/sidekiq 6.7 | Aug 2026 |
| Production host | fish-eagle (Ubuntu 16.04) | martial-eagle (Ubuntu 24.04) | Oct 2026 |
| Security | — | SQL-injection/XSS/`send` fixes, route lockdown, rack-attack + `AttackProtectionMiddleware` | Aug 2025 → Oct 2026 |

Details, open items and the remaining roadmap (Dockerfile outdated, Sidekiq 8, CSP, jQuery replacement): `documentation/MODERNIZATION_PLAN.md`; completed plans and design specs: `documentation/plans/` and `documentation/specs/`; index of all docs: `documentation/README.md`.

## Maintenance

- Run `bundle update` monthly for security patches; review dependencies quarterly; watch deprecation warnings in logs.
- Keep test coverage at 100%; run all three suites before claiming any change is done.
- Regular Brakeman and dependency vulnerability scans; security header reviews.
- Open roadmap items (Dockerfile outdated, Sidekiq 8 upgrade, Content Security Policy, jQuery replacement) are tracked in `documentation/MODERNIZATION_PLAN.md`.
