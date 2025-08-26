# Redis connection configuration
redis_options = {
  host: Rails.env.production? ? 'localhost' : '127.0.0.1',
  port: 6379,
  db: 0,
  # Timeout settings to match Sidekiq configuration
  timeout: 5,        # General timeout
  read_timeout: 5,   # Prevent ReadTimeoutError
  write_timeout: 5,  # Write operations timeout
  connect_timeout: 2 # Connection establishment timeout
}

$redis = Redis.new(redis_options)
