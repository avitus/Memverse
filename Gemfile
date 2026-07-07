# encoding: utf-8
require 'rbconfig'

# Use secure version (can remove once using Bundler 2.0)
git_source(:github) { |name| "https://github.com/#{name}.git" }

# Set Ruby version (we are using RVM)
ruby "3.2.6"

HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do
  gem 'web-console', '~> 4.2'                                   # Rails 7 compatible version
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'spring', '~> 2.1'                                        # Application preloader for Rails 6 compatibility
  gem 'listen', '~> 3.2'                                        # File system change monitoring for Rails 6
  gem 'brakeman', :require => false                             # Scan for security vulnerabilities
  gem 'letter_opener'                                           # Preview email in development browser
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'                                   # Automatic test metadata collection for CirclCI
  gem 'rails-controller-testing'                                # To use 'assigns' in controller tests
  gem 'factory_bot_rails'                                       # Add to development group for debugging in console
  gem 'cucumber-rails', require: false                          # Rails Generators for Cucumber with special support for Capybara and DatabaseCleaner
  gem 'capybara'                                                # Helps test web applications by simulating how a real user would interact with your app
  gem 'puma', '~> 7.2'                                          # Dev/test web server (CVE-2025: PROXY protocol DoS fixed in 7.2.1); prod uses Passenger
  gem 'selenium-webdriver'                                      # Optional extension for Capybara
  gem 'webdrivers'                                              # Automatically downloads and manages webdriver versions
  gem 'database_cleaner'                                        # Clean database between tests
  gem 'launchy', '>= 2.0.5'
  gem 'email_spec'                                              # For sending email in cucumber tests
  gem 'action_mailer_cache_delivery', '>= 0.3.5'                # Used to test email delivery with Cucumber. Pairs with email_spec
  gem 'guard', '>= 0.6.2'
  gem 'guard-minitest'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'faker'                                                   # Generates fake test data
end

############################################################
# Database
############################################################
gem 'mysql2', '>= 0.4'
gem 'redis', '~> 5.0'                                                          # Redis Key-value store - updated for Ruby 3.2 compatibility

############################################################
# Javascript Rutime
############################################################

# Use Node.js as the Javascript Runtime
# No need to install libv8 or rubyracer gems any more.

############################################################
# Frameworks
############################################################
gem 'rails', '~> 7.2.0', '>= 7.2.3.1'                                          # Rails 7.2; floor pins the 7.2.3.1 security release (else bundler picks 7.2.3)                                                            
gem 'jquery-rails'                                                             # Currently using jQuery 1.12.4
gem 'jquery-ui-rails'

############################################################
# Rails Support Gems
############################################################
gem 'bootsnap', '>= 1.4.2', require: false                                     # Boot optimization for Rails 6
gem 'sass-rails', '>= 6.0'
gem 'autoprefixer-rails', '~> 10.4.21'                                         # CSS vendor prefixes - Rails 7 and Ruby 3.2 compatible
gem 'terser'                                                                   # JS compressor (replaces uglifier for Rails 7)                   
gem "mimemagic", "~> 0.3.10"                                                   # For mime type detection. Prev version yanked      
gem 'ffi', '~> 1.16.0'                                                         # FFI library - Ruby 3.2 compatible

# Rails 7 components
gem 'actionmailbox', '~> 7.2.0'                                                # Inbound email handling
gem 'actiontext', '~> 7.2.0'                                                   # Rich text content
gem 'sprockets-rails'                                                          # Asset pipeline for Rails 7
gem 'importmap-rails'                                                          # Modern JS without webpack
gem 'turbo-rails'                                                              # Hotwire Turbo for SPA-like performance
gem 'stimulus-rails'                                                           # Hotwire Stimulus for JS behavior

############################################################
# API
############################################################
gem 'doorkeeper'                                                               # Oauth for API
gem 'swagger-blocks'                                                           # Generates swagger-ui json files
gem 'jbuilder'

############################################################
# Authentication and Authorization
############################################################
gem 'devise', '~> 5.0'                                                          # Authentication
gem 'devise-encryptable'                                                       # TODO: Is this required?
gem 'omniauth'                                                                 # Multi-provider authentication
gem 'cancancan', '~> 3.4'                                                      # Role-based authorization

############################################################
# Major Engines (Admin, Forem, Blog)
############################################################
gem 'rails_admin'                                                              # Admin dashboard
gem 'thredded', '~> 1.2.1'                                                     # Forum engine - Rails 7 and Ruby 3.2 compatible
gem 'bloggity', github: 'avitus/bloggity', branch: 'rails7-upgrade'            # Blog engine (Rails 7 compatible)
# gem 'bloggity', :path => "../bloggity"                                       # Blog engine (dev environment)

############################################################
# Deployment and Monitoring
############################################################
gem 'capistrano', "~> 3.8"                                                     # Deploy with Capistrano
gem 'capistrano-rails'                                                         # Rails-specific tasks for Capistrano
gem 'capistrano-rvm'                                                           # RVM-specific config for Capistrano
gem 'ed25519', '>= 1.2', '< 2.0'                                              # SSH ED25519 key support for deployment
gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0'                                         # SSH key encryption support for deployment
gem 'sitemap_generator'                                                        # Sitemap generator
gem 'newrelic_rpm', '>=3.3.0'                                                  # Performance monitoring
gem "sentry-raven"                                                             # Error tracking


############################################################
# Messaging
############################################################
gem 'pubnub', '~> 5.5.0'                                                      # Real-time messaging service - updated to latest
gem 'rpush', '~> 9.2.0'                                                        # Push notification service - Rails 7.1 compatible
gem 'mail', '>= 2.2.15'                                                        # Emails
gem 'postmark-rails', '~> 0.22'                                                # Postmark email delivery service

############################################################
# Scheduled Tasks
############################################################
gem 'sidekiq', '~> 7.3'                                                        # Background jobs - latest stable version
gem "sidekiq-cron", "~> 2.0"                                                   # Scheduler for Sidekiq - major version upgrade
gem 'ice_cube'                                                                 # For calculating next quiz
gem 'fugit'                                                                    # Cron expression parser for next run calculations
gem 'capistrano-sidekiq'                                                       # Sidekiq integration for Capistrano

############################################################
# Blog
############################################################
gem 'ckeditor', '~> 5.1'                                                       # WYSIWYG editing

############################################################
# Voting System
############################################################
gem 'acts_as_votable'                                                          # Add voting to any model

############################################################
# Other Gems -- should be grouped better
############################################################
# gem 'fancybox2-rails'                                                        # REMOVED: Replaced with MicroModal for video/modal displays
gem 'kaminari'                                                                 # Required for bloggity
gem 'rinku', require: 'rails_rinku'                                            # Supports auto-linking of URL's in blog comments
gem 'randumb'                                                                  # Retrieve a random record
gem 'prawn'                                                                    # PDF support
gem "prawnto_2", require: "prawnto"                                            # Integrating prawn into Rails
gem 'acts-as-taggable-on', '~> 11.0'                                           # 11.0 supports activerecord < 8.0 (Rails 7.2)
gem 'nokogiri', '>=1.5.0'                                                      # HTML/XML parsing
gem 'json'                                                                     # Javascript Object Notation support
gem 'thinking-sphinx'                                                          # Connector to Sphinx - for global search
gem "i18n-js", ">= 3.0.0.rc11"                                                 # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'breadcrumbs_on_rails', '>=2.0.0'                                          # For breadcrumb navigation bar
gem 'dalli', '~> 3.2'                                                          # Memcached client - Rails 7 compatible
gem 'friendly_id'                                                              # Makes nice IDs for models
gem 'foreman'                                                                  # Helps manage multiple processes when running app in development.
gem 'best_in_place', '~> 4.0'                                                  # In-place editing support (Rails 7 compatible)
gem 'dropbox-sdk'                                                              # Used with backup above
gem 'rack-utf8_sanitizer'                                                      # Used to fix EasouSpider invalid UTF-8 byte sequences
gem 'responders', '~> 3.0'                                                     # Support for respond_to and respond_with

group :console do
  gem 'wirble'
  gem 'hirb'
end


# TODO

# rake acts_as_taggable_on_engine:install:migration  <-- this fails
# DONE: Updated thredded gem to ~> 1.2.1 for Ruby 3.2 compatibility
# DONE: Updated autoprefixer-rails to ~> 10.4.21 for Ruby 3.2 compatibility  
# DONE: Updated redis to ~> 5.0 for better Rails 7 support
# DONE: Updated ffi to ~> 1.16.0 for Ruby 3.2 compatibility
# TODO: Consider migrating from best_in_place to Stimulus/Turbo for Rails 7+
# Add backup gem back in ... couldn't resolve nokogiri dependency to match that of Thredded
gem "sassc-rails"

############################################################
# Ruby 3.2 Standard Library Gems 
# These gems were moved out of the standard library and need to be explicitly included
############################################################
gem 'net-http'                                                 # HTTP client library - used in app/lib/esv.rb
gem 'rss'                                                      # RSS parser library - used in app/lib/rss_reader.rb
