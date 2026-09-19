default_origins = %w[
  https://avitus.github.io
  http://localhost:5078
  http://localhost:5000
  https://localhost:5001
]

allowed_origins = ENV.fetch('MEMVERSE_CORS_ALLOWED_ORIGINS', default_origins.join(','))
                     .split(',')
                     .map(&:strip)
                     .reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource '/oauth/token',
             headers: %w[Authorization Content-Type],
             methods: %i[get post patch put delete options]

    resource '/oauth/revoke',
             headers: %w[Authorization Content-Type],
             methods: %i[post options]

    resource '/api/v1/*',
             headers: %w[Authorization Content-Type],
             methods: %i[get post patch put delete options]
  end
end
