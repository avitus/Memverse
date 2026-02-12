# frozen_string_literal: true

# Manages SSE connections for quiz events with proper resource management
class SseConnectionManager
  include Singleton

  MAX_CONNECTIONS_PER_USER = 3
  MAX_TOTAL_CONNECTIONS = 500
  CONNECTION_TTL = 3600 # 1 hour
  REDIS_PREFIX = 'sse:connections'

  def initialize
    @connections = {}
    @mutex = Mutex.new
    @redis = Redis.new
  end

  # Register a new SSE connection
  def register_connection(user_id, quiz_id, connection_id)
    connection_to_close = nil

    @mutex.synchronize do
      # Check global connection limit
      if total_connections >= MAX_TOTAL_CONNECTIONS
        raise ConnectionLimitExceeded, "Maximum total connections (#{MAX_TOTAL_CONNECTIONS}) reached"
      end

      # Check per-user connection limit
      user_connections = user_connection_count(user_id)
      if user_connections >= MAX_CONNECTIONS_PER_USER
        # Find oldest connection for this user
        connection_to_close = find_oldest_user_connection(user_id)
      end

      # Store connection info
      connection_key = "#{REDIS_PREFIX}:#{connection_id}"
      connection_data = {
        user_id: user_id,
        quiz_id: quiz_id,
        connected_at: Time.current.to_i,
        last_heartbeat: Time.current.to_i
      }

      @redis.setex(connection_key, CONNECTION_TTL, connection_data.to_json)

      # Add to user's connection set
      user_key = "#{REDIS_PREFIX}:users:#{user_id}"
      @redis.sadd(user_key, connection_id)
      @redis.expire(user_key, CONNECTION_TTL)

      # Track in memory for quick access
      @connections[connection_id] = {
        user_id: user_id,
        quiz_id: quiz_id,
        thread: Thread.current
      }

      Rails.logger.info "SSE: Registered connection #{connection_id} for user #{user_id} on quiz #{quiz_id}"
    end

    # Close oldest connection outside the synchronized block
    if connection_to_close
      close_connection(connection_to_close)
    end
  end

  # Unregister a connection
  def unregister_connection(connection_id)
    @mutex.synchronize do
      connection = @connections.delete(connection_id)
      return unless connection

      # Remove from Redis
      @redis.del("#{REDIS_PREFIX}:#{connection_id}")

      # Remove from user's connection set
      user_key = "#{REDIS_PREFIX}:users:#{connection[:user_id]}"
      @redis.srem(user_key, connection_id)

      Rails.logger.info "SSE: Unregistered connection #{connection_id}"
    end
  end

  # Update heartbeat for a connection
  def update_heartbeat(connection_id)
    connection_key = "#{REDIS_PREFIX}:#{connection_id}"
    connection_data = @redis.get(connection_key)
    return unless connection_data

    data = JSON.parse(connection_data)
    data['last_heartbeat'] = Time.current.to_i
    @redis.setex(connection_key, CONNECTION_TTL, data.to_json)
  end

  # Get total number of active connections
  def total_connections
    @redis.keys("#{REDIS_PREFIX}:*").count { |key| !key.include?(':users:') }
  end

  # Get number of connections for a specific user
  def user_connection_count(user_id)
    @redis.scard("#{REDIS_PREFIX}:users:#{user_id}").to_i
  end

  # Find the oldest connection for a user
  def find_oldest_user_connection(user_id)
    user_key = "#{REDIS_PREFIX}:users:#{user_id}"
    connection_ids = @redis.smembers(user_key)

    oldest_connection = nil
    oldest_time = nil

    connection_ids.each do |conn_id|
      conn_data = @redis.get("#{REDIS_PREFIX}:#{conn_id}")
      next unless conn_data

      data = JSON.parse(conn_data)
      if oldest_time.nil? || data['connected_at'] < oldest_time
        oldest_time = data['connected_at']
        oldest_connection = conn_id
      end
    end

    oldest_connection
  end

  # Close a specific connection
  def close_connection(connection_id)
    # Kill the thread if it exists
    connection = nil
    @mutex.synchronize do
      connection = @connections[connection_id]
    end

    if connection && connection[:thread] && connection[:thread] != Thread.current && connection[:thread].alive?
      connection[:thread].raise(ConnectionTerminated.new("Connection limit exceeded"))
    end

    unregister_connection(connection_id)
  end

  # Clean up stale connections
  def cleanup_stale_connections
    stale_connections = []

    @mutex.synchronize do
      stale_time = Time.current.to_i - 300 # 5 minutes

      @redis.keys("#{REDIS_PREFIX}:*").each do |key|
        next if key.include?(':users:')

        connection_data = @redis.get(key)
        next unless connection_data

        data = JSON.parse(connection_data)
        if data['last_heartbeat'] < stale_time
          connection_id = key.split(':').last
          Rails.logger.info "SSE: Cleaning up stale connection #{connection_id}"
          stale_connections << connection_id
        end
      end
    end

    # Unregister connections outside the synchronized block to avoid deadlock
    stale_connections.each do |connection_id|
      unregister_connection(connection_id)
    end
  end

  # Get connection statistics
  def stats
    {
      total_connections: total_connections,
      connections_by_user: connections_by_user,
      memory_connections: @connections.size
    }
  end

  private

  def connections_by_user
    user_counts = {}
    @redis.keys("#{REDIS_PREFIX}:users:*").each do |key|
      user_id = key.split(':').last.to_i
      user_counts[user_id] = @redis.scard(key).to_i
    end
    user_counts
  end

  class ConnectionLimitExceeded < StandardError; end
  class ConnectionTerminated < StandardError; end
end