# frozen_string_literal: true

# Ultra-early logging for debugging
# This runs before Rails fully loads

require 'logger'

class RackRequestLogger
  def initialize(app, logger = nil)
    @app = app
    @logger = logger || Logger.new(Rails.root.join('log', "rack_debug_#{Rails.env}.log"))
  end

  def call(env)
    if env['PATH_INFO'] =~ /moderation/ && env['REQUEST_METHOD'] == 'POST'
      @logger.info "[RACK] ====== Moderation POST Request ======"
      @logger.info "[RACK] Time: #{Time.now}"
      @logger.info "[RACK] Path: #{env['PATH_INFO']}"
      @logger.info "[RACK] Method: #{env['REQUEST_METHOD']}"
      @logger.info "[RACK] Remote IP: #{env['REMOTE_ADDR']}"
      @logger.info "[RACK] User Agent: #{env['HTTP_USER_AGENT']}"
      @logger.info "[RACK] Content Type: #{env['CONTENT_TYPE']}"
      @logger.info "[RACK] Content Length: #{env['CONTENT_LENGTH']}"

      begin
        status, headers, response = @app.call(env)
        @logger.info "[RACK] Response Status: #{status}"
        @logger.info "[RACK] Response Headers: #{headers.inspect}"

        # Check if response is HTML without DOCTYPE
        if headers['Content-Type']&.include?('text/html') && status == 500
          body = ""
          response.each { |part| body << part.to_s }
          @logger.info "[RACK] Response body starts with: #{body[0..200]}"
          response = [body] # Reset response for downstream
        end

        [status, headers, response]
      rescue => e
        @logger.error "[RACK] Exception in app: #{e.class} - #{e.message}"
        @logger.error "[RACK] Backtrace:\n#{e.backtrace.first(10).join("\n")}"
        raise
      end
    else
      @app.call(env)
    end
  end
end

# Insert at the very beginning of the middleware stack
Rails.application.config.middleware.insert 0, RackRequestLogger

# Also log that this file loaded
Rails.logger.info "[RACK LOGGER] Rack request logger installed at #{Time.now}"
puts "[STARTUP] Rack request logger installed" if Rails.env.production?