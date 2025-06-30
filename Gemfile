# encoding: utf-8
require 'rbconfig'

# Use secure version (can remove once using Bundler 2.0)
git_source(:github) { |name| "https://github.com/#{name}.git" }

# Set Ruby version (we are using RVM)
ruby "2.4.10"

HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do
  gem 'web-console'
  gem 'rails-footnotes', '>= 3.7'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'spring'
  gem 'brakeman', :require => false                             # Scan for security vulnerabilities
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'                                   # Automatic test metadata collection for CirclCI
  gem 'rails-controller-testing'                                # To use 'assigns' in controller tests
  gem 'jasmine'
  # gem 'jasmine-rails'
  gem 'sqlite3'
  gem 'factory_bot_rails'                                       # Add to development group for debugging in console
  gem 'cucumber-rails', require: false                          # Rails Generators for Cucumber with special support for Capybara and DatabaseCleaner
  gem 'capybara'                                                # Helps test web applications by simulating how a real user would interact with your app
  gem 'puma'
  gem 'selenium-webdriver'                                      # Optional extension for Capybara
  gem 'database_cleaner'                                        # Clean database between tests
  gem 'launchy', '>= 2.0.5'
  gem 'email_spec'                                              # For sending email in cucumber tests
  gem 'action_mailer_cache_delivery', '>= 0.3.5'                # Used to test email delivery with Cucumber. Pairs with email_spec
  # gem 'phantomjs'                                             # For wercker jasmine specs
  gem 'guard', '>= 0.6.2'
  gem 'guard-minitest'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'guard-jasmine'
  gem 'faker'                                                   # Generates fake test data
end

############################################################
# Database
############################################################
gem 'mysql2', '>= 0.4'
gem 'redis', '~> 4.0'                                                          # Redis Key-value store

############################################################
# Javascript Rutime
############################################################

# Use Node.js as the Javascript Runtime
# No need to install libv8 or rubyracer gems any more.

############################################################
# Frameworks
#
# Currently using jQuery 1.12.4 (upgrading to 3.0 will require work)
# Thredded specifies jQuery version in javascripts/threddeded/dependencies
#
############################################################
gem 'rails', '~> 5.1'                                                            
gem 'jquery-rails'                                                              # Currently using jQuery 1.12.4
gem 'jquery-ui-rails'

############################################################
# Rails Support Gems
############################################################
gem 'compass-rails'                                                             # Now has Rails 4 support
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'                                                      # Compressor for JS assets
gem 'coffee-rails', '~> 4.2' 
gem 'rails-observers'                                                           # Needed as of Rails 5.1 to observe user model                     
gem "mimemagic", "~> 0.3.10"                                                    # For mime type detection. Prev version yanked      

############################################################
# For Rails 4 Upgrade ... should be removed eventually
############################################################
# gem 'protected_attributes'                                                   # Only officially supported until Rails 5
# gem 'rails-observers' 
# gem 'actionpack-page_caching'
# gem 'actionpack-action_caching'
# gem 'activerecord-deprecated_finders'
# gem 'activerecord-session_store'                                               # We should store sessions in cookies
# gem 'activeresource', require: 'active_resource'

############################################################
# API
############################################################
# Use this version only until Rails 5 support in master branch
gem 'rocket_pants', github: 'NBuhinicek/rocket_pants'                              # API goodness
gem 'api_smith', '~> 1.3', github: 'youroute/api_smith'                        # Dependency of rocket_pant
gem 'doorkeeper'                                                               # Oauth for API
gem 'swagger-blocks'                                                           # Generates swagger-ui json files
gem 'jbuilder'

############################################################
# Authentication and Authorization
############################################################
gem 'devise'                                                                   # Authentication
gem 'devise-encryptable'                                                       # TODO: Is this required?
gem 'omniauth'                                                                 # Multi-provider authentication
gem 'omniauth-windowslive', github: 'kayle/omniauth-windowslive'               # Windows Live strategy (repo fork)
gem 'cancancan', '~> 1.10'                                                     # Role-based authorization

############################################################
# Major Engines (Admin, Forem, Blog)
############################################################
gem 'rails_admin'                                                              # Admin console
gem 'thredded', '~> 0.14.0'                                                    # Forum engine
gem 'bloggity', github: 'avitus/bloggity'                                      # Blog engine
# gem 'bloggity', :path => "../bloggity"                                       # Blog engine (dev environment)

############################################################
# Deployment and Monitoring
############################################################
gem 'capistrano', "~> 3.8"                                                     # Deploy with Capistrano
gem 'capistrano-rails'                                                         # Rails-specific tasks for Capistrano
gem 'capistrano-rvm'                                                           # RVM-specific config for Capistrano
gem 'sitemap_generator'                                                        # Sitemap generator
gem 'newrelic_rpm', '>=3.3.0'                                                  # Performance monitoring
gem "sentry-raven"                                                             # Error tracking
gem 'td'                                                                       # Event logging to Treasure Data service

############################################################
# Messaging
############################################################
gem 'pubnub'                                                                   # Real-time messaging service
gem 'rpush'                                                                    # Push notification service
gem 'mail', '>= 2.2.15'                                                        # Emails

############################################################
# Scheduled Tasks
############################################################
gem 'sidekiq'                                                                  # Background jobs; used for quizzes. TODO: Version 4 might be incompatible with Sidetiq
gem "sidekiq-cron", "~> 0.6.3"                                                 # Scheduler for Sidekiq
gem 'ice_cube'                                                                 # For calculating next quiz
gem 'capistrano-sidekiq', group: :development

############################################################
# Blog
############################################################
gem 'ckeditor', github: 'galetahub/ckeditor'                                   # WYSIWYG editing
gem 'paperclip'                                                                # Attachment handling

############################################################
# Other Gems -- should be grouped better
############################################################
# gem 'fancybox2-rails'                                                        # For displaying of video, pop-up info box
gem 'fancybox2-rails', '~> 0.3.0', github: 'ChallahuAkbar/fancybox2-rails'     # For displaying of video, pop-up info box
gem 'kaminari'                                                                 # Required for bloggity
gem 'rinku', require: 'rails_rinku'                                            # Supports auto-linking of URL's in blog comments
gem 'randumb'                                                                  # Retrieve a random record
gem 'prawn'                                                                    # PDF support
gem "prawnto_2", require: "prawnto"                                            # Integrating prawn into Rails
gem 'acts-as-taggable-on'                                                      # :source => "http://gemcutter.org", Taggable gem,
gem 'nokogiri', '>=1.5.0'                                                      # HTML/XML parsing
gem 'json'                                                                     # Javascript Object Notation support
gem 'thinking-sphinx'                                                          # Connector to Sphinx - for global search
gem "i18n-js", ">= 3.0.0.rc11"                                                 # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
# gem 'localeapp'                                                                # Translation service for i18n
gem 'breadcrumbs_on_rails', '>=2.0.0'                                          # For breadcrumb navigation bar
gem 'dalli'                                                                    # Memcached client
gem 'friendly_id'                                                              # Makes nice IDs for models
gem 'foreman'                                                                  # Helps manage multiple processes when running app in development.
gem 'best_in_place'                                                            # In-place editing support
# gem 'best_in_place', git: "https://github.com/bernat/best_in_place"            # In-place editing support
# gem 'split', require: 'split/dashboard'                                        # AB testing framework
# gem 'backup'                                                                 # Used to backup MySQL database and uploaded site assets
gem 'dropbox-sdk'                                                              # Used with backup above
gem 'rack-utf8_sanitizer'                                                      # Used to fix EasouSpider invalid UTF-8 byte sequences
gem 'responders', '~> 2.4'                                                     # Support for respond_to and respond_with in Rails 4.2

group :console do
  gem 'wirble'
  gem 'hirb'
end


# TODO

# rake acts_as_taggable_on_engine:install:migration  <-- this fails
# find replacement for best_in_place gem
# Add backup gem back in ... couldn't resolve nokogiri dependency to match that of Thredded
