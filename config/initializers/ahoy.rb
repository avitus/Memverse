# frozen_string_literal: true

# First-party analytics (ahoy_matey). Visits and events are stored in MySQL
# (ahoy_visits, ahoy_events); nothing is sent to a third party.
# See documentation/ANALYTICS.md for what is tracked and how to query it.
module Ahoy
  # Database-backed store for visits and events (the gem default), storing the
  # landing page and referrer without their query strings: confirmation and
  # password-reset links carry one-time tokens, and utm_* values are extracted
  # into their own columns before this runs.
  class Store < Ahoy::DatabaseStore
    def track_visit(data)
      data[:landing_page] = strip_query(data[:landing_page])
      data[:referrer]     = strip_query(data[:referrer])
      super
    end

    private

    def strip_query(url)
      return url if url.blank?

      uri = URI.parse(url)
      uri.query = nil
      uri.fragment = nil
      uri.to_s
    rescue URI::InvalidURIError
      url.split("?").first
    end
  end
end

# Page views and events are recorded server-side (AnalyticsTracking concern);
# no JavaScript tracker and no /ahoy API endpoint.
Ahoy.api = false

# No geocoding: we do not need city-level location and it would add a lookup per visit.
Ahoy.geocode = false

# Privacy: IPs are stored with the last octet zeroed.
Ahoy.mask_ips = true

# Visitor and visit tokens live in first-party cookies (ahoy_visitor, ahoy_visit).
# The cookieless mode would identify a visitor by IP + user agent, which merges
# different people behind one network and can attach one user's events to
# another user's visit. Cookies keep each person's visit separate.
Ahoy.cookie_options = {
  same_site: :lax,
  secure: !Rails.env.development? && !Rails.env.test?
}

# Crawlers are excluded automatically (Ahoy.track_bots defaults to false).
Ahoy.user_method = :current_user

# Skip visit tracking for the same controllers whose page views are not
# recorded (admin tooling, API), so they create no ahoy_visits rows either.
Ahoy.exclude_method = lambda do |controller, _request|
  controller.respond_to?(:untracked_controller?, true) && controller.send(:untracked_controller?)
end
