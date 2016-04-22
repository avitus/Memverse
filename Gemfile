# encoding: utf-8
require 'rbconfig'

HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do
  gem 'rails-footnotes', '>= 3.7'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'guard', '>= 0.6.2'
  gem 'guard-minitest'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-cucumber'
  gem 'guard-jasmine'
  gem 'brakeman', :require => false                             # Scan for security vulnerabilities
end

group :development, :test do
  gem 'rspec-rails'
  gem 'jasmine'
  gem 'jasmine-rails'
end

group :test do
  gem 'sqlite3'
  gem 'factory_girl_rails'                                      # Add to development group for debugging in console
  gem 'cucumber-rails', '>= 1.3.0', require: false
  gem "capybara", '>= 1.1.2'
  gem 'selenium-webdriver'                                      # Optional extension for Capybara
  gem 'database_cleaner', '= 1.0.1'                             # TODO: Newer version has bug with database adapter ... upgrade when possible
  gem 'launchy', '>= 2.0.5'
  gem 'email_spec'                                              # For sending email in cucumber tests
  gem 'action_mailer_cache_delivery', '>= 0.3.5'                # Used to test email delivery with Cucumber. Pairs with email_spec
  gem 'phantomjs'                                               # For wercker jasmine specs
end

group :production do
  gem 'mysql2', '>= 0.3'
  gem 'yui-compressor'
end

############################################################
# Javascript Engine
############################################################
if HOST_OS =~ /linux/i
  gem 'libv8', '= 3.11.8.17', platforms: :ruby                  # Later versions have no binary support for x86
  gem 'therubyracer', '= 0.11.4'                                # TODO: Can roll to 0.12 once binary support for libv8 3.16
end

############################################################
# Frameworks
############################################################
gem 'rails', '4.0.9'
gem 'jquery-rails', '>= 2.0.0'

############################################################
# Rails Support Gems
############################################################
gem 'sass-rails',   '~> 4.0.0'
gem 'compass-rails'                                                             # Now has Rails 4 support
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'

############################################################
# For Rails 4 Upgrade ... should be removed eventually
############################################################
gem 'protected_attributes', '>=1.0.5'
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
gem 'rails_admin', '>= 0.6.0'                                                  # Admin console
gem 'forem',       github: 'radar/forem', branch: 'rails4'                     # Forum engine
gem 'forem-textile_formatter'                                                  # Forum formatting
gem 'bloggity',    github: 'alexcwatt/bloggity'                                # Blog engine
# gem 'bloggity', :path => "../bloggity"                                       # Blog engine (dev environment)

############################################################
# Deployment and Monitoring
############################################################
gem 'capistrano', '=2.15.5'                                                    # Deploy with Capistrano
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
gem 'sidekiq', '< 4'                                                           # Background jobs; used for quizzes. TODO: Version 4 might be incompatible with Sidetiq
gem 'sidetiq'                                                                  # Scheduled Sidekiq jobs
gem 'ice_cube'                                                                 # For calculating next quiz
gem 'capistrano-sidekiq', group: :development

############################################################
# Blog
############################################################
gem 'ckeditor'                                                                 # WYSIWYG editing
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
gem 'thinking-sphinx', '~> 3.0.5'                                              # Connector to Sphinx - for global search
gem 'i18n-js'                                                                  # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'localeapp'                                                                # Translation service for i18n
gem 'breadcrumbs_on_rails', '>=2.0.0'                                          # For breadcrumb navigation bar
gem 'dalli'                                                                    # Memcached client
gem 'redis', '>=2.2.2'                                                         # Redis Key-value store
gem 'friendly_id'                                                              # Makes nice IDs for models
gem 'foreman'                                                                  # Helps manage multiple processes when running app in development.
gem 'best_in_place', github: 'bernat/best_in_place'                            # In-place editing support ... no Rails 4 release yet
gem 'split', require: 'split/dashboard'                                        # AB testing framework
gem 'backup'                                                                   # Used to backup MySQL database and uploaded site assets
gem 'dropbox-sdk'                                                              # Used with backup above
gem 'sinatra', require: false                                                  # sinatra and slim are required for sidekiq
gem 'slim'
gem 'net-ssh', '2.7.0'                                                         # Used by capistrano among other gems. 2.8.0 had significant bug.
gem 'rack-utf8_sanitizer'                                                      # Used to fix EasouSpider invalid UTF-8 byte sequences

group :console do
  gem 'wirble'
  gem 'hirb'
end
