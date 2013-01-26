# encoding: utf-8
require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do
  # gem 'query_reviewer', :git => "git://github.com/nesquena/query_reviewer.git"                # For finding slow queries ... problems with Rails 3.2 (?)
	gem "rails-footnotes", ">= 3.7"
  gem 'sqlite3'
  gem 'better_errors'
  gem 'binding_of_caller'
end

gem "rspec-rails", ">= 2.6.1", :group => [:development, :test]
gem 'jasmine', :group => [:development, :test]

group :test do
  gem "factory_girl_rails", ">= 1.2.0"
  gem "cucumber-rails", ">= 1.1.1", require: false
  gem "capybara", ">= 1.1.2"
  gem "database_cleaner", ">= 0.6.7"
  gem "launchy", ">= 2.0.5"
end

group :production do
  gem 'mysql2', '>= 0.3'
end

group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
end

if HOST_OS =~ /linux/i
  gem 'libv8', '>= 3.11.8.13', :platforms => :ruby
  gem 'therubyracer', '>= 0.11.3'
end

gem 'rails', '3.2.11'
gem 'jquery-rails', '>= 2.0.0'

gem "devise"                                                                                    # Authentication
gem "devise-encryptable"                                                                        # TODO: Is this required?
gem "cancan"                                                                                    # Role-based authorization

gem 'rails_admin', :git => 'git://github.com/sferik/rails_admin.git'                            # Admin console
gem 'forem',       :git => "git://github.com/radar/forem.git"                                   # Forum engine
gem 'bloggity',    :git => "git://github.com/avitus/bloggity.git"                               # Blog engine
# gem 'bloggity', :path => "../bloggity"                                                        # Blog engine (dev environment)

gem 'fancybox-rails'                                                                            # For displaying of video
gem 'kaminari'                                                                                  # Required for bloggity
gem 'rinku', :require => 'rails_rinku'                                                          # Supports auto-linking of URL's in blog comments
gem 'randumb'                                                                                   # Retrieve a random record
gem 'prawn', :git => "git://github.com/sandal/prawn", :submodules => true                       # PDF support
gem "prawnto_2", :require => "prawnto"                                                          # Integrating prawn into Rails
gem 'acts-as-taggable-on'                                                                       # :source => "http://gemcutter.org", Taggable gem,
gem 'airbrake'                                                                                  # Error tracking
gem 'ckeditor'                                                                                  # WYSIWYG editing
gem 'paperclip'                                                                                 # Attachment handling
gem 'capistrano', '>=2.9.0'                                                                     # Deploy with Capistrano
gem 'nokogiri', '>=1.5.0'                                                                       # HTML/XML parsing
# gem 'test-unit', '=1.2.3'                                                                     # Required for restful_authentication (?)
gem 'json'                                                                                      # Javascript Object Notation support
gem 'mail', '>= 2.2.15'                                                                         # Emails
gem 'newrelic_rpm', '>=3.3.0'                                                                   # Performance monitoring
gem 'thinking-sphinx', '~> 2.0.14'                                                              # Connector to Sphinx - for global search
gem 'riddle'                                                                                    # Seems to be needed for Thinking_Sphinx ... not clear, though
gem 'i18n-js'                                                                                   # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'spawn', '>=1.2', :git => 'git://github.com/avitus/spawn.git', :branch => 'edge'            # Check to see whether master branch ever supports Rails 3 & Ruby 1.92
gem 'juggernaut', '>=2.1.0', :git => 'git://github.com/maccman/juggernaut.git'                  # Live chat
gem 'htmldiff'                                                                                  # For showing errors in accuracy test
gem 'breadcrumbs_on_rails', '>=2.0.0'                                                           # For breadcrumb navigation bar
gem 'dalli'                                                                                     # Memcached client
gem 'redis', '>=2.2.2'                                                                          # Redis Key-value store
gem 'action_mailer_cache_delivery', git: 'git://github.com/ragaskar/action_mailer_cache_delivery.git' # Used to test email delivery with Cucumber
gem 'friendly_id'                                                                               # Makes nice IDs for models
gem 'foreman'                                                                                   # Helps manage multiple processes when running app in development.
gem 'supermodel', git: 'git://github.com/KonaTeam/supermodel.git'                               # Uses ActiveModel for in-memory storage with redis
gem 'best_in_place'                                                                             # In-place editing support
gem 'sitemap_generator'                                                                         # Sitemap generator
gem 'split', :require => 'split/dashboard'                                                      # AB testing framework

group :console do
  gem 'wirble'
  gem 'hirb'
end

group :test do
  gem 'email_spec'
end