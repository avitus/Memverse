# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
- **Unit tests**: `bundle exec rspec`
- **Integration tests**: `bundle exec cucumber features`
- **JavaScript tests**: `bundle exec rake spec:javascript RAILS_ENV=test`
- **Individual test file**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Run specific cucumber feature**: `bundle exec cucumber features/path/to/feature.feature`

### Development
- **Start server**: `bundle exec rails server` or `foreman start` (manages multiple processes)
- **Rails console**: `bundle exec rails console`
- **Database migration**: `bundle exec rake db:migrate`
- **Assets precompilation**: `bundle exec rake assets:precompile`
- **Background jobs**: Sidekiq is used for background processing

### Other Tasks
- **Custom rake tasks**: Available in `lib/tasks/` - memverse.rake, quiz.rake, roster.rake, etc.

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

### API & Documentation
- **RocketPants**: API framework 
- **Swagger-blocks**: API documentation generation
- Models include Swagger schema definitions

### Database
- **MySQL**: Primary database
- **Redis**: Caching and background job queue
- **Thinking Sphinx**: Full-text search integration

### Frontend & Assets
- **jQuery 1.12.4**: JavaScript framework
- **SASS**: CSS preprocessing  
- **CoffeeScript**: JavaScript preprocessing
- **Jasmine**: JavaScript testing framework

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
- **Jasmine**: JavaScript unit testing
- **FactoryBot**: Test data generation
- **Database Cleaner**: Test database management

## Technical Debt Modernization Plan

### 1. Framework & Language Upgrades
- Upgrade Ruby from 2.7.8 to 3.2+ (current stable)
- Upgrade Rails from 5.1 to 7.1+ (latest stable)
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
- Replace Jasmine with Jest/Vitest for JavaScript testing
- Upgrade RSpec and Cucumber to latest versions
- Implement proper CI/CD pipeline with automated testing
- Add code coverage reporting (SimpleCov)
- Remove deprecated testing gems (guard-*)

### 7. Security Updates
- Update all gems with known vulnerabilities
- Implement Content Security Policy
- Add proper API rate limiting
- Update authentication gems (Devise, OmniAuth)
- Implement proper secrets management

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

**Note**: This modernization should be done incrementally, starting with security updates and framework upgrades, then moving to frontend modernization while maintaining backward compatibility during the transition period.