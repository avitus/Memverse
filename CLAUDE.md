# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Related Documentation
- **[STYLE_GUIDE.md](./STYLE_GUIDE.md)** - Visual design standards and CSS conventions
- **[UPGRADE_PLAN.md](./UPGRADE_PLAN.md)** - Rails/Ruby modernization roadmap
- **[GEM_COMPATIBILITY_AUDIT.md](./GEM_COMPATIBILITY_AUDIT.md)** - Gem compatibility analysis

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
- **Start server**: `bundle exec rails server` or `foreman start` (manages multiple processes)
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

This is a Ruby on Rails 5.1 Bible memorization application with a traditional MVC architecture.

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
- **RocketPants**: API framework 
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
| Rails | 5.2.8.1 | 7.0.8.7 | ✅ Complete |
| File Storage | Paperclip | Active Storage | ✅ Complete |
| JavaScript Testing | Jasmine | Vitest | ✅ Complete |
| API Framework | RocketPants | Rails API | ✅ Complete |
| Email Service | Sendgrid | Postmark | ✅ Complete |
| Test Coverage | 100% | 100% | ✅ Maintained |

**Test Results**:
- RSpec: 325/325 passing (100%)
- Cucumber: 33/33 scenarios passing (100%)
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
```bash
# Deploy using Capistrano
cap production deploy

# Or manual deployment:
git pull origin master
bundle install --deployment --without development test
npm ci --production
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake assets:precompile RAILS_ENV=production
touch tmp/restart.txt
```

#### Post-Deployment Verification
- Test all critical user paths (login, memorization, uploads)
- Monitor error tracking (Sentry) for 24-48 hours
- Check performance metrics (New Relic)
- Verify background job processing (Sidekiq)
- Confirm file uploads working with Active Storage

### Next Phase: Rails 7.1+ Upgrade (PLANNED)

**Prerequisites**: All current upgrades stable in production

**Key Tasks**:
1. Migrate from secrets.yml to Rails credentials system
2. Update to Rails 7.1.5 or latest stable
3. Apply Rails 7.1 configuration defaults
4. Update remaining gem dependencies
5. Consider Sidekiq 8.0 upgrade (requires Ruby 3.0+)

**Timeline**: 3-4 weeks after Ruby 3.2.6 stabilizes

### Future Modernization Roadmap

#### Phase 1: Core Infrastructure (Next 3-6 months)
- [ ] Complete Rails 7.1+ upgrade
- [ ] Implement Docker containerization
- [ ] Migrate to modern CI/CD pipeline
- [ ] Add comprehensive monitoring (APM)

#### Phase 2: Frontend Modernization (Optional, 6-12 months)
- [ ] Add Stimulus.js for progressive enhancement
- [ ] Gradually replace jQuery with vanilla JS
- [ ] Implement modern build pipeline (Vite/esbuild)
- [ ] Consider Tailwind CSS for new components

#### Phase 3: Architecture Improvements (12+ months)
- [ ] Implement service object pattern
- [ ] Add API versioning strategy
- [ ] Consider GraphQL for modern API needs
- [ ] Evaluate microservices for specific features

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

**Progress Update**: The Memverse application has successfully completed major modernization milestones including Rails 7.0, Ruby 3.2.6, Active Storage migration, and comprehensive security fixes. All systems are production-ready with 100% test coverage maintained throughout. The next priority is stabilizing in production before proceeding with Rails 7.1+ upgrade.
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

### 1. Framework & Language Upgrades (NEXT PRIORITY)
- Upgrade Ruby from 2.7.8 to 3.2+ (current stable)
- Upgrade Rails from 5.2.8.1 to 7.1+ (latest stable)
- Update all gems to Rails 7 compatible versions
- Remove deprecated gems (rails-observers, protected_attributes references)

### 2. Frontend Modernization
- Replace jQuery 1.12.4 with modern JavaScript (ES6+/TypeScript)
- Migrate from CoffeeScript to modern JavaScript
- Replace Asset Pipeline with Webpack/Vite/esbuild
- Implement modern CSS framework (Tailwind/Bootstrap 5)
- Remove jQuery UI and legacy jQuery plugins
- Implement modern state management (React/Vue/Stimulus)

### 3. API Modernization
- Replace RocketPants (unmaintained) with Rails API mode
- Migrate from Swagger-blocks to modern API documentation (OpenAPI 3.0)
- Implement GraphQL as alternative to REST
- Modernize OAuth implementation with current Doorkeeper

### 4. Background Processing
- Upgrade Sidekiq from 6.5 to latest version
- Replace sidekiq-cron with native Sidekiq Enterprise/Pro features or solid_queue
- Consider migrating to Rails 7's built-in Active Job

### 5. Database & Search
- Upgrade MySQL connector and optimize queries
- Replace Thinking Sphinx with Elasticsearch/OpenSearch
- Implement database connection pooling
- Add database performance monitoring

### 6. Testing Infrastructure
- ✅ Replace Jasmine with Vitest for JavaScript testing (COMPLETED)
- Upgrade RSpec and Cucumber to latest versions
- Implement proper CI/CD pipeline with automated testing
- Add code coverage reporting (SimpleCov)
- Remove deprecated testing gems (guard-*)

### 7. Additional Security Hardening
- Implement Content Security Policy
- Add proper API rate limiting
- Update authentication gems (Devise, OmniAuth)
- Implement proper secrets management
- Complete migration away from default routes (partial completion achieved)

### 8. Deployment & Infrastructure
- Containerize application with Docker
- Replace Capistrano with modern deployment (Kubernetes/ECS)
- Implement proper environment configuration (dotenv)
- Add application performance monitoring (APM)
- Implement proper logging infrastructure

### 9. Code Quality & Maintenance
- Remove dead code and unused dependencies
- Implement proper linting (RuboCop, ESLint)
- Add type checking (Sorbet/RBS for Ruby)
- Refactor fat controllers and models
- Implement service objects pattern

### 10. Third-party Dependencies
- Replace unmaintained gems (bloggity, fancybox2-rails)
- Update or replace CKEditor with modern editor
- Modernize file upload handling (Active Storage vs Paperclip)
- Update real-time features (Action Cable vs PubNub)

### 11. Performance Optimization
- Implement proper caching strategy (Redis)
- Add CDN for static assets
- Optimize database queries (N+1 queries)
- Implement lazy loading for images/assets
- Add proper pagination/infinite scroll

### 12. Development Experience
- Add proper development environment setup (Docker Compose)
- Implement hot module replacement
- Add proper debugging tools
- Create comprehensive documentation
- Implement feature flags system

**Progress Update**: Critical security vulnerabilities have been addressed as the first phase of modernization. The application now has significantly improved security with all tests passing at 100%. The next priority should be framework upgrades (Ruby/Rails) to ensure continued security support and access to modern features.