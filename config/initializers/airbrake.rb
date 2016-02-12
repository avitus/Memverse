require 'airbrake/sidekiq/error_handler'

Airbrake.configure do |config|
  config.project_key = 'ff93297e3cf047ed49d1468851347641'
  config.project_id = 16073
  config.environment = Rails.env
  config.ignore_environments = %w(development test cucumber)
end


# This can be removed once we upgrade to Passenger v 5.0 (ALV Feb 2016)
Airbrake.add_filter do |notice|
  # See: https://github.com/phusion/passenger/issues/1730
  passenger_error = proc do |error|
    error[:backtrace].empty? &&
      error[:type] == 'NoMethodError' && 
      error[:message] =~ %r{undefined method `call'}
  end

  notice.ignore! if notice[:errors].any?(&passenger_error)
end