# Temporary redesign preview: live database, isolated runtime services.
require_relative "production"

Rails.application.configure do
  config.force_ssl = true
  config.action_mailer.perform_deliveries = false
  config.action_mailer.default_url_options = { host: 'staging.memverse.com', protocol: 'https' }
  config.active_record.dump_schema_after_migration = false
  config.hosts = ['staging.memverse.com']
end
