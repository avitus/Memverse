# encoding: utf-8
require 'rbconfig'
HOST_OS = RbConfig::CONFIG['host_os']
source 'http://rubygems.org'

group :development do 
  # gem 'query_reviewer', :git => "git://github.com/nesquena/query_reviewer.git"                  # For finding slow queries ... problems with Rails 3.2 (?)
	gem "rails-footnotes", ">= 3.7", :group => :development
  gem 'sqlite3'
end

group :production do
  gem 'mysql2', '>= 0.3'
end

group :assets do
  gem 'sass-rails', "  ~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
end

if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end

gem 'rails', '3.2.4'
gem 'jquery-rails', '=1.0.18'

gem "rspec-rails", ">= 2.6.1", :group => [:development, :test]
gem "factory_girl_rails", ">= 1.2.0", :group => :test
gem "cucumber-rails", ">= 1.0.2", :group => :test
gem "capybara", ">= 1.1.2", :group => :test
gem "database_cleaner", ">= 0.6.7", :group => :test
gem "launchy", ">= 2.0.5", :group => :test
gem 'jasmine', :group => [:development, :test]

gem "devise"                                                                                    # Authentication
gem "devise-encryptable"                                                                        # TODO: Is this required?
gem "cancan"                                                                                    # Role-based authorization

gem 'rails_admin', :git => 'git://github.com/sferik/rails_admin.git'                            # Admin console
gem 'forem', :git => "git://github.com/radar/forem.git"                                         # Forum engine

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
gem 'nokogiri', '1.4.6'                                                                         # HTML/XML parsing
gem 'test-unit', '=1.2.3'                                                                       # Required for restful_authentication (?)
gem 'json'                                                                                      # Javascript Object Notation support
gem 'mail', '>= 2.2.15'                                                                         # Emails
gem 'newrelic_rpm', '>=3.3.0'                                                                   # Performance monitoring
gem 'thinking-sphinx', '>=2.0.10'                                                               # Connector to Sphinx - for global search
gem 'riddle'                                                                                    # Seems to be needed for Thinking_Sphinx ... not clear, though
gem 'i18n-js'                                                                                   # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'spawn', '>=1.2', :git => 'git://github.com/avitus/spawn.git', :branch => 'edge'            # Check to see whether master branch ever supports Rails 3 & Ruby 1.92
gem 'juggernaut', '>=2.1.0', :git => 'git://github.com/maccman/juggernaut.git'                  # Live chat
gem 'htmldiff'                                                                                  # For showing errors in accuracy test
gem 'breadcrumbs_on_rails', '>=2.0.0'                                                           # For breadcrumb navigation bar
gem 'memcache-client'                                                                           # Memcached client
gem 'redis', '>=2.2.2'                                                                          # Redis Key-value store
gem 'action_mailer_cache_delivery', git: 'git://github.com/ragaskar/action_mailer_cache_delivery.git' # Used to test email delivery with Cucumber
gem 'friendly_id'                                                                               # Makes nice IDs for models
gem 'foreman'                                                                                   # Helps manage multiple processes when running app in development.
gem 'supermodel', git: 'git://github.com/KonaTeam/supermodel.git'                               # Uses ActiveModel for in-memory storage with redis
gem 'best_in_place'                                                                             # In-place editing support

group :console do
  gem 'wirble'
  gem 'hirb'
end

group :test do
  gem 'email_spec'
end