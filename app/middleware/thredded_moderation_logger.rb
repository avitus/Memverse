class ThreddedModerationLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    # Only log moderation requests
    if env['PATH_INFO'] == '/forum/admin/moderation' && env['REQUEST_METHOD'] == 'POST'
      Rails.logger.info "[MODERATION MIDDLEWARE] Request received"
      Rails.logger.info "[MODERATION MIDDLEWARE] Path: #{env['PATH_INFO']}"
      Rails.logger.info "[MODERATION MIDDLEWARE] Method: #{env['REQUEST_METHOD']}"
      Rails.logger.info "[MODERATION MIDDLEWARE] Content-Type: #{env['CONTENT_TYPE']}"

      # Log request body if present
      if env['rack.input']
        body = env['rack.input'].read
        env['rack.input'].rewind  # Reset for subsequent middleware
        Rails.logger.info "[MODERATION MIDDLEWARE] Body: #{body[0..500]}" # First 500 chars

        # Parse params if form data
        if env['CONTENT_TYPE']&.include?('application/x-www-form-urlencoded')
          params = Rack::Utils.parse_nested_query(body)
          Rails.logger.info "[MODERATION MIDDLEWARE] Parsed params: #{params.inspect}"
        end
      end

      begin
        status, headers, response = @app.call(env)
        Rails.logger.info "[MODERATION MIDDLEWARE] Response status: #{status}"
        [status, headers, response]
      rescue => e
        Rails.logger.error "[MODERATION MIDDLEWARE] Exception: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        raise
      end
    else
      @app.call(env)
    end
  end
end