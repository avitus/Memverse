$redis = Redis.new(:host => (ENV['WERCKER_REDIS_HOST'] || 'localhost'), :port => 6379)
