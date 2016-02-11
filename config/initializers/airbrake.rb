require 'airbrake/sidekiq/error_handler'

Airbrake.configure do |config|
  config.project_key = 'ff93297e3cf047ed49d1468851347641'
  config.project_id = 16073
  config.environment = Rails.env
  config.ignore_environments = %w(development test cucumber)
end
