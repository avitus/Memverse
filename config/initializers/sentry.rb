# Error tracking.
# Release is intentionally NOT set here: sentry-ruby auto-detects it from
# SENTRY_RELEASE, then Capistrano's REVISION file, then the local git SHA —
# so production events are tagged with the exact deployed commit.
Sentry.init do |config|
  config.dsn = 'https://a1106f25de724396a866c6ab9386b11b@sentry.io/299442'
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger]
end