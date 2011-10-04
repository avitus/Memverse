require 'rbconfig'
HOST_OS = Config::CONFIG['host_os']
source 'http://rubygems.org'

group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

if HOST_OS =~ /linux/i
  gem 'therubyracer', '>= 0.8.2'
end

gem "rspec-rails", ">= 2.6.1", :group => [:development, :test]
gem "factory_girl_rails", ">= 1.2.0", :group => :test
gem "cucumber-rails", ">= 1.0.2", :group => :test
gem "capybara", ">= 1.1.1", :group => :test
gem "database_cleaner", ">= 0.6.7", :group => :test
gem "launchy", ">= 2.0.5", :group => :test
gem "devise", ">= 1.4.5"
gem "frontend-helpers"
gem "rails-footnotes", ">= 3.7", :group => :development
gem 'rails_admin', :git => 'git://github.com/sferik/rails_admin.git'


gem 'rails', '3.1.0'
gem 'jquery-rails'
gem 'sqlite3'
gem 'mysql2', '>= 0.3'
gem 'aasm', '2.2.0',    :require => 'aasm'                                                      # :source => 'http://gems.github.com',   
gem 'will_paginate', '>=3.0.pre'                                                                # :source => 'http://gemcutter.org', will_paginate is required for bloggity
gem 'randumb'                                                                                   # Retrieve a random record
gem 'prawn', :git => "git://github.com/sandal/prawn", :submodules => true                       # PDF support
gem "prawnto_2", :require => "prawnto"                                                          # Integrating prawn into Rails
gem 'acts-as-taggable-on'                                                                       # :source => "http://gemcutter.org", Taggable gem, 
gem 'airbrake'                                                                                  # Error tracking
gem 'paperclip'                                                                                 # :source => 'http://rubygems.org', Attachment handling 
gem 'capistrano'                                                                                # Deploy with Capistrano
gem 'ruby-openid'
gem 'ziya', '>=2.3.0'                                                                           # Required for flash charts
gem 'color'                                                                                     # Required for Ziya
gem 'logging'                                                                                   # Required for Ziya
gem 'builder'                                                                                   # Required for Ziya
gem 'nokogiri', '1.4.6'                                                                         # HTML/XML parsing
gem 'test-unit', '=1.2.3'                                                                       # Required for restful_authentication (?)
gem 'json'                                                                                      # Javascript Object Notation support
gem 'mail', '>= 2.2.15'                                                                         # Emails
gem 'newrelic_rpm', '>=3.0.0'                                                                   # Performance monitoring
gem 'thinking-sphinx', '>=2.0.0', :require => 'thinking_sphinx'                                 # Connector to Sphinx - for global search
gem 'riddle'                                                                                    # Seems to be needed for Thinking_Sphinx ... not clear, though
gem 'i18n-js'                                                                                   # Uses config/locale files to build a JavaScript equivalent of i18n in Rails
gem 'spawn', :git => 'git://github.com/jpfuentes2/spawn'                                        # Use this for now (instead of the plugin ... check to see whether master branch ever supports Rails 3)
gem 'juggernaut', '>=2.0.1', :git => 'git://github.com/maccman/juggernaut.git'
gem 'htmldiff'                                                                                  # For showing errors in accuracy test
gem 'breadcrumbs_on_rails', '>=2.0.0'                                                           # For breadcrumb navigation bar
gem 'query_reviewer', :git => "git://github.com/nesquena/query_reviewer.git"                    # For finding slow queries
gem 'memcache-client'                                                                           # Memcached client
gem 'redis', '>=2.2.0'                                                                          # Redis Key-value store


group :console do
  gem 'wirble'
  gem 'hirb'
end