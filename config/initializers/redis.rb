if Rails.env.production?

	# In production Redis is on localhost listening on port 6379
	$redis = Redis.new(:host => 'localhost', :port => 6379)

else

	# In dev/test we will be using a docker container called 'redis'
	# $redis = Redis.new(:host => (ENV['REDIS_HOST'] || 'redis'), :port => 6379)
	$redis = Redis.new(:host => '127.0.0.1', :port => 6379)


end
