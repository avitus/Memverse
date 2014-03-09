# encoding: utf-8
require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do
	gem 'rails-footnotes', '>= 3.7'
  gem 'sqlite3'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
end

gem 'rspec-rails', '>= 2.6.1', :group => [:development, :test]
gem 'jasmine', :group => [:development, :test]

group :test do
  gem 'factory_girl_rails'                                      # Add to development group for debugging in console
  gem 'cucumber-rails', '>= 1.3.0', require: false
  gem "capybara", '>= 1.1.2'
  gem 'selenium-webdriver'                                      # Optional extension for Capybara
  gem 'database_cleaner', '= 1.0.1'                             # TODO: Newer version has bug with database adapter ... upgrade when possible
  gem 'launchy', '>= 2.0.5'
  gem 'email_spec'                                              # For sending email in cucumber tests
  gem 'action_mailer_cache_delivery', '>= 0.3.5'                # Used to test email delivery with Cucumber. Pairs with email_spec
end

group :production do
  gem 'mysql2', '>= 0.3'
end

############################################################
# Javascript Engine
############################################################
if HOST_OS =~ /linux/i
  gem 'libv8', '= 3.11.8.17', :platforms => :ruby               # Later versions have no binary support for x86
  gem 'therubyracer', '= 0.11.4'                                # TODO: Can roll to 0.12 once binary support for libv8 3.16
end

############################################################
# Frameworks
############################################################
gem 'rails', '4.0.3'
gem 'jquery-rails', '>= 2.0.0'

############################################################
# Rails Support Gems
############################################################
gem 'sass-rails',   '~> 4.0.0'
gem 'compass-rails'                                             # Now has Rails 4 support
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
gem 'doorkeeper', '~> 0.7.0'                                                   # Oauth for API

############################################################
# Authentication and Authorization
############################################################
gem 'devise'                                                                   # Authentication
gem 'devise-encryptable'                                                       # TODO: Is this required?
gem 'omniauth'                                                                 # Multi-provider authentication
gem 'omniauth-windowslive'                                                     #   - strategy for Windows live
gem 'cancan', github: 'nukturnal/cancan'                                       # Role-based authorization, Forem requires

############################################################
# Major Engines (Admin, Forem, Blog)
############################################################
gem 'rails_admin', '>= 0.6.0'                                                  # Admin console
gem 'forem',       github: 'radar/forem', branch: 'rails4'                     # Forum engine
gem 'forem-textile_formatter'                                                  # Forum formatting
gem 'bloggity',    github: 'avitus/bloggity'                                   # Blog engine
# gem 'bloggity', :path => "../bloggity"                                       # Blog engine (dev environment)

############################################################
# Deployment and Monitoring
############################################################
gem 'capistrano', '=2.15.5'                                                    # Deploy with Capistrano
gem 'sitemap_generator'                                                        # Sitemap generator
gem 'newrelic_rpm', '>=3.3.0'                                                  # Performance monitoring
gem 'airbrake'                                                                 # Error tracking

gem 'fancybox2-rails'                                                          # For displaying of video, pop-up info box
gem 'kaminari'                                                                 # Required for bloggity
gem 'rinku', :require => 'rails_rinku'                                         # Supports auto-linking of URL's in blog comments
gem 'randumb'                                                                  # Retrieve a random record
gem 'prawn', github: 'sandal/prawn', :submodules => true                       # PDF support
gem "prawnto_2", :require => "prawnto"                                         # Integrating prawn into Rails
gem 'acts-as-taggable-on'                                                      # :source => "http://gemcutter.org", Taggable gem,
gem 'ckeditor'                                                                 # WYSIWYG editing
gem 'paperclip'                                                                # Attachment handling
gem 'nokogiri', '>=1.5.0'                                                      # HTML/XML parsing
gem 'json'                                                                     # Javascript Object Notation support
gem 'mail', '>= 2.2.15'                                                        # Emails
gem 'thinking-sphinx', '~> 3.0.5'                                              # Connector to Sphinx - for global search
gem 'i18n-js'                                                                  # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'localeapp'                                                                # Translation service for i18n
gem 'breadcrumbs_on_rails', '>=2.0.0'                                          # For breadcrumb navigation bar
gem 'dalli'                                                                    # Memcached client
gem 'redis', '>=2.2.2'                                                         # Redis Key-value store
gem 'friendly_id', '5.0.2'                                                     # !!! TODO: Upgrade !!! Makes nice IDs for models
gem 'foreman'                                                                  # Helps manage multiple processes when running app in development.
gem 'supermodel', github: 'KonaTeam/supermodel'                                # Uses ActiveModel for in-memory storage with redis
gem 'best_in_place', github: 'bernat/best_in_place'                            # In-place editing support ... no Rails 4 release yet
gem 'split', :require => 'split/dashboard'                                     # AB testing framework
gem 'backup'                                                                   # Used to backup MySQL database and uploaded site assets
gem 'dropbox-sdk'                                                              # Used with backup above
gem 'sidekiq'                                                                  # Background jobs; used for quizzes
gem 'sidetiq'                                                                  # Scheduled Sidekiq jobs
gem 'ice_cube'                                                                 # For calculating next quiz
gem 'sinatra', require: false                                                  # sinatra and slim are required for sidekiq
gem 'slim'
gem 'pubnub'                                                                   # Real-time messaging service
gem 'paranoia'                                                                 # destroy on selected models doesn't actually remove from database ... soft-deletion

group :console do
  gem 'wirble'
  gem 'hirb'
end
