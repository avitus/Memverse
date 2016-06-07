$redis = Redis.new(:host => (ENV['WERCKER_REDIS_HOST'] || 'redis'), :port => 6379)
