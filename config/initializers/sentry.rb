# Error tracking.
# Release is intentionally NOT set here: sentry-ruby auto-detects it —
# SENTRY_RELEASE env var, then the local git SHA, then Capistrano's REVISION
# file — so production events are tagged with the exact deployed commit
# (Capistrano release dirs have no .git, so REVISION wins in production).
Sentry.init do |config|
  config.dsn = 'https://a1106f25de724396a866c6ab9386b11b@sentry.io/299442'
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger]
end
