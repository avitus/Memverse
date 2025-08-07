# Disable Devise email sending during tests to prevent view rendering issues
if Rails.env.test?
  # Skip confirmation emails entirely in test environment
  Devise.setup do |config|
    config.confirm_within = nil  # Disable confirmation timeouts
    config.send_email_changed_notification = false
    config.send_password_change_notification = false
  end
  
  # Set default URL options for tests
  Rails.application.routes.default_url_options = { host: 'localhost:3000' }
end