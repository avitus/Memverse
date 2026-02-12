# frozen_string_literal: true

# Middleware for rate limiting SSE connections to quiz endpoints
# Uses Redis to track requests per IP with sliding window algorithm
class QuizSseThrottle
  # Rate limit configuration
  RATE_LIMIT = 10 # requests
  TIME_WINDOW = 60 # seconds (1 minute)
  REDIS_PREFIX = 'rate_limit:quiz_sse'

  # Response headers
  RATE_LIMIT_HEADER = 'X-RateLimit-Limit'
  RATE_LIMIT_REMAINING_HEADER = 'X-RateLimit-Remaining'
  RATE_LIMIT_RESET_HEADER = 'X-RateLimit-Reset'

  def initialize(app)
    @app = app
    @redis = Redis.new
  end

  def call(env)
    request = Rack::Request.new(env)

    # Skip rate limiting in test environment
    return @app.call(env) if Rails.env.test?

    # Only apply rate limiting to quiz SSE endpoints
    if quiz_sse_endpoint?(request)
      ip_address = get_client_ip(request)

      # Check rate limit
      if rate_limited?(ip_address)
        return rate_limit_exceeded_response(ip_address)
      end

      # Track the request
      track_request(ip_address)

      # Add rate limit headers to response
      status, headers, response = @app.call(env)
      add_rate_limit_headers(headers, ip_address)

      [status, headers, response]
    else
      @app.call(env)
    end
  rescue => e
    Rails.logger.error "QuizSseThrottle error: #{e.message}"
    # If Redis is down or there's an error, allow the request through
    @app.call(env)
  end

  private

  def quiz_sse_endpoint?(request)
    request.path.match?(%r{^/live_quiz/(events|quiz_state)})
  end

  def get_client_ip(request)
    # Use ActionDispatch remote_ip detection which handles proxies/CDNs
    request.env['action_dispatch.remote_ip']&.to_s ||
      request.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip ||
      request.env['REMOTE_ADDR']
  end

  def rate_limited?(ip_address)
    key = "#{REDIS_PREFIX}:#{ip_address}"
    count = @redis.get(key).to_i
    count >= RATE_LIMIT
  end

  def track_request(ip_address)
    key = "#{REDIS_PREFIX}:#{ip_address}"

    # Use Redis MULTI for atomic operations
    @redis.multi do |multi|
      multi.incr(key)
      multi.expire(key, TIME_WINDOW)
    end
  end

  def rate_limit_exceeded_response(ip_address)
    key = "#{REDIS_PREFIX}:#{ip_address}"
    ttl = @redis.ttl(key)
    reset_time = Time.current.to_i + ttl

    headers = {
      'Content-Type' => 'application/json',
      RATE_LIMIT_HEADER => RATE_LIMIT.to_s,
      RATE_LIMIT_REMAINING_HEADER => '0',
      RATE_LIMIT_RESET_HEADER => reset_time.to_s
    }

    body = {
      error: 'Rate limit exceeded',
      message: "Too many requests. Please try again in #{ttl} seconds.",
      retry_after: ttl
    }.to_json

    [429, headers, [body]]
  end

  def add_rate_limit_headers(headers, ip_address)
    key = "#{REDIS_PREFIX}:#{ip_address}"
    count = @redis.get(key).to_i
    ttl = @redis.ttl(key)
    remaining = [RATE_LIMIT - count, 0].max
    reset_time = Time.current.to_i + ttl

    headers[RATE_LIMIT_HEADER] = RATE_LIMIT.to_s
    headers[RATE_LIMIT_REMAINING_HEADER] = remaining.to_s
    headers[RATE_LIMIT_RESET_HEADER] = reset_time.to_s
  end
end