MemverseApp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  if Rails.env.development?
    # Use Dalli for Memcached only if the gem is loaded
    if defined?(Dalli)
      config.cache_store = :dalli_store, '127.0.0.1:11211', {:namespace => "dev"}
    else
      # Fallback to memory store if dalli is not available
      config.cache_store = :memory_store
    end
  end

  # No need for eager loading in dev
  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # ActionMailer Config
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  # A dummy setup for development - no deliveries, but logged
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Do not compress assets
  config.assets.compress = false

  # Whitelist IP addresses
  config.web_console.whitelisted_ips = '192.168.99.1/16'

  # Check if we use Docker to allow docker ip through web-console
  if ENV['DOCKERIZED'] == 'true'
    config.web_console.whitelisted_ips = ENV['DOCKER_HOST_IP']
  end

  # Expands the lines which load the assets
  config.assets.debug = true

  # Configure Paperclip to access ImageMagick - this is the path returned by 'which convert'
  Paperclip.options[:command_path] = "/usr/local/bin/"

end
