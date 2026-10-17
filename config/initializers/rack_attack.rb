# frozen_string_literal: true

# Backstop against crawlers that ignore robots.txt and are not caught by the
# user-agent blocklist in AttackProtectionMiddleware. Limits are generous enough
# that a person reading the blog or forum never hits them.
# See documentation/ANALYTICS.md ("Bot mitigation").
require "rack/attack"

crawl_paths = %r{\A/(forum|blog)(/|\z)}

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

# Any GET under /forum or /blog: 120 requests per IP per 10 minutes.
Rack::Attack.throttle("crawl/ip", limit: 120, period: 10.minutes) do |req|
  req.ip if req.get? && req.path.match?(crawl_paths)
end

# Blog listing permutations (?page=, ?tag_name=, ?search=): 30 per IP per 10 minutes.
# These are what SEO crawlers walk exhaustively.
Rack::Attack.throttle("blog-listings/ip", limit: 30, period: 10.minutes) do |req|
  req.ip if req.get? && req.path.start_with?("/blog") && !req.query_string.empty?
end

Rack::Attack.throttled_responder = lambda do |req|
  retry_after = (req.env["rack.attack.match_data"] || {})[:period]
  [429,
   { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
   ["Too many requests. Please slow down.\n"]]
end

# Enabled in production and development; request specs turn it on explicitly.
Rack::Attack.enabled = !Rails.env.test?
