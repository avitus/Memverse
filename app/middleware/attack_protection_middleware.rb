# frozen_string_literal: true

# Middleware to protect against common web attacks including:
# 1. WordPress/PHP path probing attacks
# 2. IP spoofing attempts with conflicting headers
#
# This middleware runs early in the request cycle to block malicious
# requests before they reach the application or trigger errors.
class AttackProtectionMiddleware
  # Common WordPress/PHP attack paths that should be blocked
  BLOCKED_PATHS = [
    # WordPress admin and login paths
    '/wp-login.php',
    '/wp-admin',
    '/wp-content',
    '/wp-includes',
    '/xmlrpc.php',
    '/wp-config.php',
    '/wp-cron.php',
    '/wp-load.php',
    '/wp-signup.php',

    # PHP admin tools
    '/phpmyadmin',
    '/pma',
    '/phpMyAdmin',
    '/myadmin',
    '/mysql',
    '/dbadmin',
    '/websql',
    '/mysqladmin',

    # Other common attack vectors
    '/admin.php',
    '/administrator',
    '/config.php',
    '/database.php',
    '/.env',
    '/env',
    '/.git/config',
    '/backup.sql',
    '/wp-config.php.bak'
  ].freeze

  # Known malicious user agents patterns
  BLOCKED_USER_AGENTS = [
    /sqlmap/i,
    /nikto/i,
    /wpscan/i,
    /masscan/i,
    /nmap/i,
    /metasploit/i,
    /havij/i,
    /acunetix/i
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    # Check for blocked paths
    if blocked_path?(request.path)
      Rails.logger.warn("Blocked attack path: #{request.path} from #{request.ip}")
      return not_found_response
    end

    # Check for malicious user agents
    if blocked_user_agent?(request.user_agent)
      Rails.logger.warn("Blocked malicious user agent: #{request.user_agent} from #{request.ip}")
      return forbidden_response
    end

    # Handle IP spoofing attempts gracefully
    begin
      @app.call(env)
    rescue ActionDispatch::RemoteIp::IpSpoofAttackError => e
      handle_ip_spoofing_attempt(request, e)
    end
  end

  private

  def blocked_path?(path)
    BLOCKED_PATHS.any? { |blocked| path.downcase.start_with?(blocked) }
  end

  def blocked_user_agent?(user_agent)
    return false if user_agent.nil?

    BLOCKED_USER_AGENTS.any? { |pattern| user_agent.match?(pattern) }
  end

  def handle_ip_spoofing_attempt(request, error)
    # Log the spoofing attempt with details
    Rails.logger.warn do
      <<~LOG
        IP Spoofing attempt detected:
        Path: #{request.path}
        User-Agent: #{request.user_agent}
        HTTP_CLIENT_IP: #{request.env['HTTP_CLIENT_IP']}
        HTTP_X_FORWARDED_FOR: #{request.env['HTTP_X_FORWARDED_FOR']}
        REMOTE_ADDR: #{request.env['REMOTE_ADDR']}
        Error: #{error.message}
      LOG
    end

    # Return 403 Forbidden without sending to Sentry
    # This prevents noise in error tracking for known attack patterns
    forbidden_response
  end

  def not_found_response
    [
      404,
      {
        'Content-Type' => 'text/html',
        'X-Attack-Protection' => 'blocked-path'
      },
      ['<html><body><h1>404 Not Found</h1></body></html>']
    ]
  end

  def forbidden_response
    [
      403,
      {
        'Content-Type' => 'text/html',
        'X-Attack-Protection' => 'blocked-request'
      },
      ['<html><body><h1>403 Forbidden</h1></body></html>']
    ]
  end
end
