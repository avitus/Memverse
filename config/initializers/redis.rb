if Rails.env = 'production'

	# In production Redis is on localhost listening on port 6379
	$redis = Redis.new

else
	
	# In dev/test we will be using a docker container called 'redis'
	$redis = Redis.new(:host => (ENV['WERCKER_REDIS_HOST'] || 'redis'), :port => 6379)

end
