# require File.expand_path('../boot', __FILE__)
require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
# Bundler.require(:default, Rails.env)
Bundler.require(*Rails.groups)

# ActiveSupport::Deprecation.debug = true

module MemverseApp
  class Application < Rails::Application
    
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # don't generate RSpec tests for views and helpers
    config.generators do |g|
      g.view_specs false
      g.helper_specs false
      g.stylesheets false
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Require by Grape. Only need for Rails 5.2 and below. See inflections.rb for Rails 6 solution
    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    # CORS support for Grape API
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
      end
    end

    # Fallback on en if translation missing
    config.i18n.fallbacks = true
    config.i18n.fallbacks = [:en]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Currently, Active Record suppresses errors raised within after_rollback or after_commit callbacks and only prints them to the logs. 
    # In the next version, these errors will no longer be suppressed. Instead, the errors will propagate normally just like in other Active Record callbacks.
    # When you define an after_rollback or after_commit callback, you will receive a deprecation warning about this upcoming change. 
    # When you are ready, you can opt into the new behavior and remove the deprecation warning by adding following configuration to your config/application.rb:
    # config.active_record.raise_in_transactional_callbacks = true

    ### BEGIN: Fix EasouSpider invalid UTF-8 byte sequences
    require "#{Rails.root}/lib/handle_invalid_percent_encoding.rb"

    # NOTE: These must be in this order relative to each other.
    # HandleInvalidPercentEncoding just raises for encoding errors it doesn't cover,
    # so it must run after (= be inserted before) Rack::UTF8Sanitizer.
    config.middleware.insert 0, HandleInvalidPercentEncoding
    config.middleware.insert 0, Rack::UTF8Sanitizer  # from a gem

    ### END: Fix EasouSpider invalid UTF-8 byte sequences

  end
end
