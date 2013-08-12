MemverseApp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  #===============================
  # Caching
  #===============================
  config.cache_classes = true                      # Code is not reloaded between requests
  config.consider_all_requests_local = false       # Full error reports are disabled
  config.cache_store = :dalli_store                # Use Memcached for cache
  config.action_controller.perform_caching = true

  config.eager_load = true

  #===============================
  # Asset Pipeline
  #===============================
  config.assets.compress = true               # Compress Javascript and CSS
  config.assets.js_compressor  = :uglifier    # Javascript compression
  config.assets.digest = true                 # Generate digests for assets URLs
  config.serve_static_assets = false          # Disable Rails's static asset server (Apache or nginx will already do this)

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true # This should be false but seems to be a problem with Rails Admin ... try again with Rails 3.1.3

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )
  config.assets.precompile += %w(rails_admin/rails_admin.js rails_admin/rails_admin.css) # This is a temporary workaround until Rails 3.1.1 Should be able to remove

  # Ensure that Ckeditor assets are precompiled
  config.assets.precompile += Ckeditor.assets

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  #===============================
  # Content Delivery Network
  #===============================
  config.action_controller.asset_host = "http://d1r0kpcohdg1bn.cloudfront.net"  # Amazon Cloudfront
  config.static_cache_control = "public, max-age=86400"
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # Header that Nginx uses for sending files

  #===============================
  # Logging
  #===============================
  config.logger = Logger.new(config.paths['log'].first, 5, 100.megabytes)  # Let Rails handle log rotation
  config.log_level = :info
  config.active_support.deprecation = :notify     # Send deprecation notices to registered listeners

  #===============================
  # Email
  #===============================
  config.action_mailer.default_url_options = { :host => 'memverse.com' }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false  # ignore bad email addresses
  config.action_mailer.default :charset => "utf-8"
  config.action_mailer.delivery_method = :smtp

  # Gmail
  # config.action_mailer.smtp_settings = {
  #   :address              => "smtp.gmail.com",
  #   :port                 => 587,
  #   :domain               => 'memverse.com',
  #   :user_name            => 'admin@memverse.com',
  #   :password             => 'Veetle77',
  #   :authentication       => "plain",
  #   :enable_starttls_auto => true  }

  # Mandrill
  config.action_mailer.smtp_settings = {
    :address   => "smtp.mandrillapp.com",
    :port      => 25,                        # ports 587 and 2525 are also supported with STARTTLS
    :enable_starttls_auto => true,           # detects and uses STARTTLS
    :user_name => "admin@memverse.com",
    :password  => "JztsJPoUBOfo4nCyEKf1MQ",  # SMTP password is any valid API key
    :authentication => 'login',              # Mandrill supports 'plain' or 'login'
    :domain => 'memverse.com',               # your domain to identify your server when connecting
  }

  #===============================
  # Miscellaneous
  #===============================

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Configure Paperclip to access ImageMagick - this is the path returned by 'which convert'
  Paperclip.options[:command_path] = "/usr/local/bin/"

  # Enable threaded mode
  # config.threadsafe!

  # Load dependencies when running a rake task
  config.dependency_loading = true if $rails_rake_task

  # https://github.com/ezmobius/redis-rb/wiki/redis-rb-on-Phusion-Passenger
  # if defined?(PhusionPassenger)
    # PhusionPassenger.on_event(:starting_worker_process) do |forked|
      # # We're in smart spawning mode.
      # if forked
        # # Re-establish redis connection
        # require 'redis'
        # redis_config = YAML.load_file("#{Rails.root.to_s}/config/redis.yml")[Rails.env]
#
        # # The important two lines
        # $redis.client.disconnect
        # $redis = Redis.new(:host => redis_config["host"], :port => redis_config["port"])
      # end
    # end
  # end


end
