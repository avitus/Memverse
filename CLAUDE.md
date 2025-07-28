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