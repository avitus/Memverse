# frozen_string_literal: true

# Backstop against crawlers that ignore robots.txt and are not caught by the
# user-agent blocklist in AttackProtectionMiddleware. Limits are generous enough
# that a person reading the blog or forum never hits them.
# See documentation/ANALYTICS.md ("Bot mitigation").
require "rack/attack"

crawl_paths = %r{\A/(forum|blog)(/|\z)}
listing_params = %w[page tag_name search category_id].freeze

# Rails answers HEAD through the GET action, so HEAD must count too.
read_request = ->(req) { req.get? || req.head? }
listing_request = lambda do |req|
  req.path.start_with?("/blog") &&
    (Rack::Utils.parse_query(req.query_string).keys & listing_params).any?
end

Rack::Attack.cache.store =
  if Rails.env.production?
    ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0"),
      namespace: "rack_attack",
      error_handler: lambda do |method:, returning:, exception:|
        Rails.logger.warn("[rack-attack] cache #{method} failed: #{exception.message}")
      end
    )
  else
    ActiveSupport::Cache::MemoryStore.new
  end

# Any GET or HEAD under /forum or /blog: 120 requests per IP per 10 minutes.
Rack::Attack.throttle("crawl/ip", limit: 120, period: 10.minutes) do |req|
  req.ip if read_request.call(req) && req.path.match?(crawl_paths)
end

# Blog listing permutations (?page=, ?tag_name=, ?search=, ?category_id=):
# 30 per IP per 10 minutes. These are what SEO crawlers walk exhaustively.
# A tracking-only query string (?utm_source=) stays on the ordinary limit.
Rack::Attack.throttle("blog-listings/ip", limit: 30, period: 10.minutes) do |req|
  req.ip if read_request.call(req) && listing_request.call(req)
end

# Retry-After is the time left in the current window, not the whole period.
Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env["rack.attack.match_data"] || {}
  period = match_data[:period].to_i
  retry_after = period.positive? ? period - (match_data[:epoch_time].to_i % period) : 0
  [429,
   { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
   ["Too many requests. Please slow down.\n"]]
end

# Enabled in production and development; request specs turn it on explicitly.
Rack::Attack.enabled = !Rails.env.test?
