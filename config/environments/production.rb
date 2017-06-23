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
  config.assets.js_compressor   = :uglifier           # Javascript compression
  config.assets.css_compressor  = :sass               # CSS compression
  config.assets.digests         = true                # Generate digests for assets URLs
  config.public_file_server.enabled = false           # Disable Rails's static asset server (Apache or nginx will already do this)

  # Don't fallback to assets pipeline if a precompiled asset is missed
  # http://stackoverflow.com/questions/8821864/config-assets-compile-true-in-rails-production-why-not
  config.assets.compile         = false

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # http://stackoverflow.com/questions/14194752/rails-4-asset-pipeline-vendor-assets-images-are-not-being-precompiled
  config.assets.precompile     += %w(*.png *.jpg *.jpeg *.gif)  # Need to support compilation of fancybox images ... shouldn't be necessary

  # Ensure that Ckeditor assets are precompiled
  config.assets.precompile     += Ckeditor.assets
  config.assets.precompile     += %w(ckeditor/*)

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest      = YOUR_PATH

  #===============================
  # Content Delivery Network
  #===============================
  config.action_controller.asset_host = "https://d1r0kpcohdg1bn.cloudfront.net"  # Amazon Cloudfront
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # Header that Nginx uses for sending files

  #===============================
  # Logging
  #===============================
  # Log file rotation no longer seems to be possible from within Rails 4
  # config.logger = Logger.new(config.paths['log'].first, 5, 100.megabytes)  # Let Rails handle log rotation
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
  # config.action_mailer.smtp_settings = {
  #   :address   => "smtp.mandrillapp.com",
  #   :port      => 25,                        # ports 587 and 2525 are also supported with STARTTLS
  #   :enable_starttls_auto => true,           # detects and uses STARTTLS
  #   :user_name => "admin@memverse.com",
  #   :password  => "JztsJPoUBOfo4nCyEKf1MQ",  # SMTP password is any valid API key
  #   :authentication => 'login',              # Mandrill supports 'plain' or 'login'
  #   :domain => 'memverse.com',               # your domain to identify your server when connecting
  # }

  # Sendgrid
  config.action_mailer.smtp_settings = {
    :user_name => 'memverse',
    :password => 'veetle77',
    :domain => 'www.memverse.com',
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
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

  # Enable garbage collection in NewRelic
  # http://technology.customink.com/blog/2012/03/16/simple-garbage-collection-tuning-for-rails/
  GC.enable_stats if defined?(GC) && GC.respond_to?(:enable_stats)

end
