require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MemverseApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Add app/lib and app/middleware to autoload paths for Rails 7.0 with Zeitwerk
    # Create a new array to avoid frozen array issues
    config.autoload_paths = config.autoload_paths.dup
    config.autoload_paths << Rails.root.join("app/lib")
    config.autoload_paths << Rails.root.join("app/middleware")
    
    # Cache format version is handled by load_defaults 7.2
    # No need to set explicitly
  end
end
