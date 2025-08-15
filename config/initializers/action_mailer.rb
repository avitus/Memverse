# Configure ActionMailer default URL options for all mailers
# This ensures Devise and other mailers use the correct host

Rails.application.config.after_initialize do
  if Rails.env.development?
    ActionMailer::Base.default_url_options = { host: 'localhost', port: 3000 }
  elsif Rails.env.test?
    ActionMailer::Base.default_url_options = { host: 'localhost', port: 3000 }
  elsif Rails.env.production?
    ActionMailer::Base.default_url_options = { host: 'www.memverse.com', protocol: 'https' }
  end
end