# encoding: utf-8
require 'rbconfig'

# Set Ruby version
ruby "2.3.1"

HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do
  gem 'web-console', '~> 2.0'
  gem 'rails-footnotes', '>= 3.7'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'brakeman', :require => false                             # Scan for security vulnerabilities
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'                                   # Automatic test metadata collection for CirclCI
  gem 'jasmine'
  gem 'jasmine-rails'
  gem 'sqlite3'
  gem 'factory_girl_rails'                                      # Add to development group for debugging in console
  gem 'cucumber-rails', require: false                          # Rails Generators for Cucumber with special support for Capybara and DatabaseCleaner
  gem "capybara"                                                # Helps test web applications by simulating how a real user would interact with your app
  gem 'selenium-webdriver'                                      # Optional extension for Capybara
  gem 'database_cleaner'                                        # Clean database between tests
  gem 'launchy', '>= 2.0.5'
  gem 'email_spec'                                              # For sending email in cucumber tests
  gem 'action_mailer_cache_delivery', '>= 0.3.5'                # Used to test email delivery with Cucumber. Pairs with email_spec
  gem 'phantomjs'                                               # For wercker jasmine specs
  gem 'guard', '>= 0.6.2'
  gem 'guard-minitest'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'guard-jasmine'
end

group :production do
  gem 'yui-compressor'
end

############################################################
# Database
############################################################
gem 'mysql2', '>= 0.4'
gem 'redis', '~> 3.2'                                                          # Redis Key-value store

############################################################
# Javascript Rutime
############################################################

# Use Node.js as the Javascript Runtime
# No need to install these gems any more.

# if HOST_OS =~ /linux/i
#   gem 'libv8', '= 3.11.8.17', platforms: :ruby                                # Later versions have no binary support for x86
#   gem 'therubyracer', '= 0.11.4'                                              # TODO: Can roll to 0.12 once binary support for libv8 3.16
# end

############################################################
# Frameworks
############################################################
gem 'rails', '4.2.6'                                                            # Last stable version was 4.0.9
gem 'jquery-rails', '>= 2.0.0'

############################################################
# Rails Support Gems
############################################################
gem 'sass-rails'
gem 'compass-rails'                                                             # Now has Rails 4 support
gem 'coffee-rails'
gem 'uglifier'

############################################################
# For Rails 4 Upgrade ... should be removed eventually
############################################################
gem 'protected_attributes'                                                     # Only officially supported until Rails 5
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'activerecord-deprecated_finders'
gem 'activerecord-session_store'                                               # We should store sessions in cookies
gem 'activeresource', require: 'active_resource'

############################################################
# API
############################################################
gem 'rocket_pants', '~> 1.0'                                                   # API goodness
gem 'doorkeeper', '~> 2.2.0'                                                   # Oauth for API
gem 'swagger-blocks'                                                           # Generates swagger-ui json files

############################################################
# Authentication and Authorization
############################################################
gem 'devise'                                                                   # Authentication
gem 'devise-encryptable'                                                       # TODO: Is this required?
gem 'omniauth'                                                                 # Multi-provider authentication
gem 'omniauth-windowslive', git: 'git://github.com/kayle/omniauth-windowslive' # Windows Live strategy
gem 'cancan', git: 'https://github.com/nukturnal/cancan.git'                   # Role-based authorization, Forem requires

############################################################
# Major Engines (Admin, Forem, Blog)
############################################################
gem 'rails_admin'                                                              # Admin console
gem 'forem',       github: 'radar/forem', branch: 'rails4'                     # Forum engine
gem 'forem-textile_formatter'                                                  # Forum formatting
gem 'bloggity',    github: 'alexcwatt/bloggity'                                # Blog engine
# gem 'bloggity', :path => "../bloggity"                                       # Blog engine (dev environment)

############################################################
# Deployment and Monitoring
############################################################
gem 'capistrano', "~> 3.5"                                                     # Deploy with Capistrano
gem 'capistrano-rails'                                                         # Rails-specific tasks for Capistrano
gem 'capistrano-rvm'                                                           # RVM-specific config for Capistrano
gem 'sitemap_generator'                                                        # Sitemap generator
gem 'newrelic_rpm', '>=3.3.0'                                                  # Performance monitoring
gem 'airbrake'                                                                 # Error tracking
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
gem 'sidetiq'                                                                  # Scheduled Sidekiq jobs
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
gem 'fancybox2-rails'                                                          # For displaying of video, pop-up info box
gem 'kaminari'                                                                 # Required for bloggity
gem 'rinku', require: 'rails_rinku'                                            # Supports auto-linking of URL's in blog comments
gem 'randumb'                                                                  # Retrieve a random record
gem 'prawn', git: "git://github.com/sandal/prawn", submodules: true            # PDF support
gem "prawnto_2", require: "prawnto"                                            # Integrating prawn into Rails
gem 'acts-as-taggable-on'                                                      # :source => "http://gemcutter.org", Taggable gem,
gem 'nokogiri', '>=1.5.0'                                                      # HTML/XML parsing
gem 'json'                                                                     # Javascript Object Notation support
gem 'thinking-sphinx'                                                          # Connector to Sphinx - for global search
gem "i18n-js", ">= 3.0.0.rc11"                                                 # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'localeapp'                                                                # Translation service for i18n
gem 'breadcrumbs_on_rails', '>=2.0.0'                                          # For breadcrumb navigation bar
gem 'dalli'                                                                    # Memcached client
gem 'friendly_id'                                                              # Makes nice IDs for models
gem 'foreman'                                                                  # Helps manage multiple processes when running app in development.
gem 'best_in_place', git: "https://github.com/bernat/best_in_place"            # In-place editing support
gem 'split', require: 'split/dashboard'                                        # AB testing framework
gem 'backup'                                                                   # Used to backup MySQL database and uploaded site assets
gem 'dropbox-sdk'                                                              # Used with backup above
gem 'sinatra', require: false                                                  # sinatra and slim are required for sidekiq
gem 'slim'
# gem 'net-ssh', '2.7.0'                                                         # Used by capistrano among other gems. 2.8.0 had significant bug.
gem 'rack-utf8_sanitizer'                                                      # Used to fix EasouSpider invalid UTF-8 byte sequences
gem 'responders', '~> 2.0'                                                     # Support for respond_to and respond_with in Rails 4.2

group :console do
  gem 'wirble'
  gem 'hirb'
end
