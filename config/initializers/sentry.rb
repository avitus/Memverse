    # Error tracking
    Raven.configure do |config|
      config.dsn = 'https://a1106f25de724396a866c6ab9386b11b:cead6cb038b44236b6e3e43887faf76d@sentry.io/299442'
      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
      config.environments = %w[ production ]
    end