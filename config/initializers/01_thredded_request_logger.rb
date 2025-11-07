# frozen_string_literal: true

# This loads early (01_ prefix) to debug Thredded moderation issues

# Create a simple middleware class
class EarlyThreddedLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] == '/forum/admin/moderation' && env['REQUEST_METHOD'] == 'POST'
      Rails.logger.info "[EARLY MIDDLEWARE] Moderation POST request intercepted"
      Rails.logger.info "[EARLY MIDDLEWARE] Headers: #{env.select { |k, v| k.start_with?('HTTP_') }.inspect}"
      Rails.logger.info "[EARLY MIDDLEWARE] Content-Type: #{env['CONTENT_TYPE']}"
      Rails.logger.info "[EARLY MIDDLEWARE] Content-Length: #{env['CONTENT_LENGTH']}"

      # Try to get CSRF token
      if env['HTTP_X_CSRF_TOKEN']
        Rails.logger.info "[EARLY MIDDLEWARE] CSRF Token present: Yes"
      else
        Rails.logger.warn "[EARLY MIDDLEWARE] CSRF Token missing!"
      end
    end
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before 0, EarlyThreddedLogger

Rails.logger.info "[STARTUP] Early middleware for Thredded moderation logging installed"