# frozen_string_literal: true

# Standard Rails middleware for handling IP spoofing errors
# This follows Rails conventions by focusing solely on IP spoofing
class IpSpoofHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::RemoteIp::IpSpoofAttackError => e
    # Log the attack for security monitoring
    Rails.logger.warn("IP Spoofing detected from #{env['REMOTE_ADDR']}: #{e.message}")

    # Return 400 Bad Request (Rails convention for client errors)
    [400,
     {'Content-Type' => 'text/plain', 'X-IP-Spoofing-Detection' => 'true'},
     ['Bad Request: IP address spoofing detected']]
  end
end