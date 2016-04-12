require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Pick the frameworks you want:

# These five frameworks were included under Rails 3.2
# require "active_record/railtie"
# require "action_controller/railtie"
# require "action_mailer/railtie"
# require "active_resource/railtie"
# require "sprockets/railtie"

# This framework was not required as of Rails 3.2
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module MemverseApp
  class Application < Rails::Application

    # don't generate RSpec tests for views and helpers
    config.generators do |g|
      g.view_specs false
      g.helper_specs false
      g.stylesheets false
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths << "#{Rails.root}/lib"  # ALV - added to load library files
    
    # config.autoload_paths += %W(#{config.root}/app/models/ckeditor) # ALV - already loaded by Rails_admin ... this is redundant

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Fallback on en if translation missing
    config.i18n.fallbacks = true
    config.i18n.fallbacks = [:en]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.5'

    # Don't require attr_accessible to be defined for every model
    config.active_record.whitelist_attributes = false

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
