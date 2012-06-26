# ACW: Implemented from https://github.com/redis/redis-rb/issues/145
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # We're in smart spawning mode.
    if forked
      # Re-establish redis connection
      require 'redis'
      redis_config = YAML.load_file("#{Rails.root.to_s}/config/redis.yml")[Rails.env]

      # The important two lines
      $redis.client.disconnect
      $redis = Redis.new(:host => redis_config["host"], :port => redis_config["port"])

      Rails.cache.reset # Only works with DalliStore
    end
  end
end
