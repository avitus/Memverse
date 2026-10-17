# frozen_string_literal: true

# First-party analytics (ahoy_matey). Visits and events are stored in MySQL
# (ahoy_visits, ahoy_events); nothing is sent to a third party.
# See documentation/ANALYTICS.md for what is tracked and how to query it.
class Ahoy::Store < Ahoy::DatabaseStore
end

# Page views and events are recorded server-side (AnalyticsTracking concern);
# no JavaScript tracker and no /ahoy API endpoint.
Ahoy.api = false

# No geocoding: we do not need city-level location and it would add a lookup per visit.
Ahoy.geocode = false

# Privacy: store masked IPs (last octet zeroed) and set no analytics cookies.
# Without cookies a visitor is identified by a hash of IP + user agent for the
# day, which is enough for counting; logged-in activity is attributed by user_id.
Ahoy.mask_ips = true
Ahoy.cookies = :none

# Crawlers are excluded automatically (Ahoy.track_bots defaults to false).
Ahoy.user_method = :current_user
