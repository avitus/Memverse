$redis = Redis.new(:host => ENV['WERCKER_REDIS_HOST'], :port => 6379)
