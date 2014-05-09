host = ENV['WERCKER_REDIS_HOST'] || 'localhost'

$redis = Redis.new(:host => host, :port => 6379)
