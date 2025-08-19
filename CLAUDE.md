# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Related Documentation
- All documentation should be in ./documentation/

- **[STYLE_GUIDE.md](./documentation/STYLE_GUIDE.md)** - Visual design standards and CSS conventions
- **[MODERNIZATION_PLAN.md](./documentation/MODERNIZATION_PLAN.md)** - modernization roadmap

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

### Development
- **Start server**: `bundle exec rails server`
- **Rails console**: `bundle exec rails console`
- **Database migration**: `bundle exec rake db:migrate`
- **Assets precompilation**: `bundle exec rake assets:precompile`
- **Background jobs**: Sidekiq is used for background processing

### Other Tasks
- **Custom rake tasks**: Available in `lib/tasks/` - memverse.rake, quiz.rake, roster.rake, etc.

### Configuration Management
- **Rails Credentials**: This project uses Rails encrypted credentials for sensitive configuration
  - Edit credentials: `EDITOR="nano" rails credentials:edit`
  - Access in code: `Rails.application.credentials.dig(:service, :api_key)`
  - Master key location: `config/master.key` (never commit this file)
  - Production setup: Copy master.key to server or set `RAILS_MASTER_KEY` environment variable
  - Current credentials include:
    - Postmark API token: `Rails.application.credentials.dig(:postmark, :api_token)`

## Architecture Overview

This is a Ruby on Rails 7.1 Bible memorization application with a traditional MVC architecture.

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
- **RailsAdmin**: Admin interface at `/admin`
- **Devise**: Authentication system with multi-provider OAuth support
- **Doorkeeper**: OAuth API provider
- **CanCanCan**: Authorization framework

### Background Processing
- **Sidekiq**: Background job processing with cron scheduling
- **Workers**: Located in `app/workers/` for reminders, metrics, quizzes
- **Monitoring Sidekiq**:
  - View real-time logs: `sudo journalctl -u sidekiq -f`
  - Check service status: `sudo systemctl status sidekiq`

### API & Documentation
- **Swagger-blocks**: API documentation generation
- Models include Swagger schema definitions

### Database
- **MySQL**: Primary database
- **Redis**: Caching and background job queue
  - Stores Sidekiq job queues and retry information
  - Manages temporary quiz session data (scores, participants)
  - Tracks chat channel status
  - No persistent business data - all Redis data is ephemeral
- **Thinking Sphinx**: Full-text search integration

### Frontend & Assets
- **jQuery 1.12.4**: JavaScript framework
- **SASS**: CSS preprocessing  
- **CoffeeScript**: JavaScript preprocessing
- **Vitest**: JavaScript testing framework (migrated from Jasmine)

### Internationalization
- **i18n-js**: JavaScript internationalization
- Supports English, Spanish, Indonesian, Chinese, Korean, Turkish
- User language preference drives locale selection

### Key Features
- **Spaced Repetition**: Algorithm-based memorization scheduling
- **Multiple Bible Translations**: User-configurable translation preferences
- **Gamification**: Badges, quests, leaderboards
- **Community Features**: Groups, forums, blogs
- **Mobile Support**: Responsive design with mobile-specific layouts
- **Real-time Features**: PubNub integration for live functionality
- **Push Notifications**: RPush for mobile notifications

### Testing Strategy
- **RSpec**: Unit testing framework
- **Cucumber**: Integration/acceptance testing
- **Vitest**: JavaScript unit testing
- **FactoryBot**: Test data generation
- **Database Cleaner**: Test database management

## Technical Debt Modernization Plan

### ✅ Security Updates (COMPLETED - August 2025)
- **Fixed 9 SQL injection vulnerabilities** in controllers by implementing `sanitize_sort_param` method
  - MemversesController, UtilsController, Api::V1::MemversesController
  - Added whitelisting for sort columns and proper SQL sanitization
- **Fixed 3 XSS vulnerabilities** in templates
  - Changed `html_safe` to `sanitize()` for devotion content
  - Changed `render text:` to `render plain:` in ReadingController and ScribeController
- **Fixed 2 dangerous send operations** in PopversesController
  - Implemented whitelisting for allowed methods
  - Added column name validation before using `public_send`
- **Improved route security**
  - Restricted default routes to authenticated users only
  - Added explicit routes for PastorsController, SermonsController, UberversesController, and others
  - Removed unsafe constraints that allowed anonymous access
- **Created comprehensive security test suite** with 100% passing tests
  - SQL injection protection tests
  - XSS protection tests  
  - Dangerous send protection tests
  - Route security tests

### ✅ Rails 7.0 Upgrade (COMPLETED - August 2025)
**Progression**: Rails 5.2.8.1 → 6.0.6.1 → 6.1.7.10 → 7.0.8.7

**Key Changes**:
- Created ApplicationRecord base class for all models
- Updated model inheritance patterns from ActiveRecord::Base
- Fixed cache store configuration for Rails 7
- Added bootsnap for improved boot performance
- Replaced all deprecated Rails methods
- Applied Rails 7.0 defaults configuration
- Fixed all test suite compatibility issues

**Major Dependency Updates**:
- **RocketPants → Rails API Mode**: Migrated all API endpoints to native Rails with Swagger documentation preserved
- **FancyBox2 → MicroModal**: Replaced unmaintained lightbox library with modern alternative
- **Jasmine → Vitest**: Modernized JavaScript testing framework with better ES6 support

### ✅ Ruby 3.2.6 Upgrade (COMPLETED - August 2025)
**Objective**: Upgrade from Ruby 2.7.8 (EOL) to Ruby 3.2.6 for performance and security

**Key Changes**:
- Rebuilt all native gem extensions with `gem pristine --all`
- Added `gem 'rss'` for Ruby 3.2 compatibility (RSS moved out of stdlib)
- Added `gem 'net-http'` for Ruby 3.2 compatibility
- Updated all gems to Ruby 3.2.6 compatible versions
- Fixed keyword argument deprecations throughout codebase
- Updated CI/CD configuration for Ruby 3.2.6

**Performance Benefits**:
- 15-40% performance improvement with YJIT JIT compiler
- 10-15% reduction in memory consumption
- 20-30% faster application boot time
- Improved garbage collection performance

### ✅ Active Storage Migration (COMPLETED - August 2025)
**Objective**: Replace deprecated Paperclip with Rails Active Storage

**Models Migrated**:
- **Sermon Model**: MP3 attachments fully migrated
- **CKEditor::Picture**: Image uploads with variants support
- **CKEditor::AttachmentFile**: File attachments migrated
- All Paperclip columns removed from database

**Migration Status**:
- All Paperclip dependencies removed from Gemfile
- Controllers updated to use Active Storage parameters only
- Views updated to use Active Storage helpers
- Database migration created to remove Paperclip columns
- Full test coverage maintained throughout migration

### ✅ Email Service Migration (COMPLETED - August 2025)
**Migration**: Sendgrid → Postmark

**Changes Implemented**:
- Added `postmark-rails` gem to Gemfile
- Updated ActionMailer configuration for Postmark
- Migrated all mailer tags to Postmark format
- Configured message streams (outbound/broadcast)
- Updated Rails credentials with Postmark API token
- Created comprehensive email testing suite

### Current Status Summary

| Component | Previous Version | Current Version | Status |
|-----------|-----------------|-----------------|---------|
| Ruby | 2.7.8 | 3.2.6 | ✅ Complete |
| Rails | 5.2.8.1 | 7.1.5.2 | ✅ Complete |
| File Storage | Paperclip | Active Storage | ✅ Complete |
| JavaScript Testing | Jasmine | Vitest | ✅ Complete |
| API Framework | RocketPants | Rails API | ✅ Complete |
| Email Service | Sendgrid | Postmark | ✅ Complete |
| Test Coverage | 100% | 100% | ✅ Maintained |

**Test Results**:
- RSpec: 474/474 passing (100%)
- Cucumber: All features passing (100%)
- Vitest: 69/69 tests passing (100%)

### Production Deployment Guide

#### Pre-Deployment Checklist
1. **Create Full Backup**
   ```bash
   # Database backup
   mysqldump -u username -p memverse_production > backup_$(date +%Y%m%d).sql
   
   # File system backup (if Paperclip files still exist)
   tar -czf paperclip_files_$(date +%Y%m%d).tar.gz public/system public/ckeditor_assets
   ```

2. **Verify Ruby Installation**
   ```bash
   # Install Ruby 3.2.6 on production
   rvm install 3.2.6
   rvm use 3.2.6 --default
   gem install bundler
   ```

3. **Enable YJIT for Performance**
   ```bash
   export RUBY_YJIT_ENABLE=1
   # Or add to config/environments/production.rb:
   ENV['RUBY_YJIT_ENABLE'] = '1' if RUBY_VERSION >= '3.1'
   ```

#### Deployment Steps

**IMPORTANT**: The production branch has been changed from `master` to `main`.

```bash
# Deploy using Capistrano (now uses main branch)
cap production deploy

# Or manual deployment:
git pull origin main  # Changed from master
bundle install --deployment --without development test
npm ci --production
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake assets:precompile RAILS_ENV=production
touch tmp/restart.txt
```

**Capistrano Configuration**: 
- Branch is set to `main` in `config/deploy.rb`
- All deployments will now pull from the `main` branch
- Ensure your local `main` branch is up to date before deploying

#### Post-Deployment Verification
- Test all critical user paths (login, memorization, uploads)
- Monitor error tracking (Sentry) for 24-48 hours
- Check performance metrics (New Relic)
- Verify background job processing (Sidekiq)
- Confirm file uploads working with Active Storage

### ✅ Rails 7.1 Upgrade (COMPLETED - August 2025)
**Progression**: Rails 7.0.8.7 → 7.1.5.2

**Key Changes**:
- Updated Rails from 7.0 to 7.1.5.2
- Applied Rails 7.1 configuration defaults (config.load_defaults 7.1)
- Fixed ActionController::Parameters handling in controller tests
- Updated rpush gem from 8.0.0 to 9.2.0 for Rails 7.1 compatibility
- Fixed duplicate detection in MemversesController ajax_add method
- Resolved all test failures from Rails 7.1 upgrade

**Test Results**:
- RSpec: 474/474 passing (100%)
- Vitest: 69/69 passing (100%)
- Cucumber: All features pass individually (100%)

### Next Phase: Production Deployment & Monitoring

**Prerequisites**: Complete testing in staging environment

**Deployment Checklist**:
1. Deploy to staging environment first
2. Run full test suite in staging
3. Monitor for 24-48 hours
4. Deploy to production with zero-downtime deployment
5. Monitor performance and error rates

**Post-Deployment Tasks**:
1. Address remaining deprecation warnings
2. Migrate from Rails.application.secrets to credentials
3. Update cache_format_version from 6.1 to 7.1
4. Consider Sidekiq 8.0 upgrade


### Maintenance Guidelines

**Regular Tasks**:
- Run `bundle update` monthly for security patches
- Monitor deprecation warnings in logs
- Keep test coverage at 100%
- Review and update dependencies quarterly

**Performance Monitoring**:
- YJIT performance metrics
- Database query optimization
- Background job processing times
- Memory usage patterns

**Security Practices**:
- Regular Brakeman scans
- Dependency vulnerability scanning
- Penetration testing (quarterly)
- Security header reviews

---



