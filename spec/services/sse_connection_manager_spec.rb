require 'rails_helper'

RSpec.describe SseConnectionManager, type: :service do
  let(:manager) { SseConnectionManager.instance }
  let(:redis) { Redis.new }

  before do
    # Clear any existing connections
    manager.instance_variable_set(:@connections, {})
    redis.flushdb
  end

  after do
    # Clean up
    manager.instance_variable_set(:@connections, {})
    redis.flushdb
  end

  describe '#register_connection' do
    it 'registers a new connection' do
      connection_id = SecureRandom.uuid
      user_id = 1
      quiz_id = 1

      expect {
        manager.register_connection(user_id, quiz_id, connection_id)
      }.not_to raise_error

      expect(manager.user_connection_count(user_id)).to eq(1)
    end

    it 'enforces per-user connection limit' do
      user_id = 1
      quiz_id = 1

      # Register max connections
      connection_ids = []
      SseConnectionManager::MAX_CONNECTIONS_PER_USER.times do |i|
        conn_id = "conn-#{i}"
        connection_ids << conn_id
        manager.register_connection(user_id, quiz_id, conn_id)
      end

      # Verify we have max connections
      expect(manager.user_connection_count(user_id)).to eq(SseConnectionManager::MAX_CONNECTIONS_PER_USER)

      # One more should succeed but close the oldest
      manager.register_connection(user_id, quiz_id, "conn-new")

      # Should still have max connections
      expect(manager.user_connection_count(user_id)).to eq(SseConnectionManager::MAX_CONNECTIONS_PER_USER)

      # The oldest connection should be gone
      expect(redis.exists?("#{SseConnectionManager::REDIS_PREFIX}:#{connection_ids.first}")).to be false

      # The new connection should exist
      expect(redis.exists?("#{SseConnectionManager::REDIS_PREFIX}:conn-new")).to be true
    end

    it 'enforces global connection limit' do
      # Mock total_connections to return max
      allow(manager).to receive(:total_connections).and_return(SseConnectionManager::MAX_TOTAL_CONNECTIONS)

      expect {
        manager.register_connection(1, 1, "conn-1")
      }.to raise_error(SseConnectionManager::ConnectionLimitExceeded)
    end
  end

  describe '#unregister_connection' do
    it 'removes a connection' do
      connection_id = SecureRandom.uuid
      user_id = 1
      quiz_id = 1

      manager.register_connection(user_id, quiz_id, connection_id)
      expect(manager.user_connection_count(user_id)).to eq(1)

      manager.unregister_connection(connection_id)
      expect(manager.user_connection_count(user_id)).to eq(0)
    end
  end

  describe '#update_heartbeat' do
    it 'updates the heartbeat timestamp' do
      connection_id = SecureRandom.uuid
      user_id = 1
      quiz_id = 1

      manager.register_connection(user_id, quiz_id, connection_id)

      # Get initial heartbeat
      conn_data = JSON.parse(redis.get("#{SseConnectionManager::REDIS_PREFIX}:#{connection_id}"))
      initial_heartbeat = conn_data['last_heartbeat']

      # Sleep for at least 1 second to ensure timestamp difference
      sleep 1.1
      manager.update_heartbeat(connection_id)

      # Get updated heartbeat
      conn_data = JSON.parse(redis.get("#{SseConnectionManager::REDIS_PREFIX}:#{connection_id}"))
      updated_heartbeat = conn_data['last_heartbeat']

      expect(updated_heartbeat).to be > initial_heartbeat
    end
  end

  describe '#cleanup_stale_connections' do
    it 'removes connections with old heartbeats' do
      connection_id = SecureRandom.uuid
      user_id = 1
      quiz_id = 1

      # Register connection with old heartbeat
      manager.register_connection(user_id, quiz_id, connection_id)

      # Manually set old heartbeat
      conn_data = JSON.parse(redis.get("#{SseConnectionManager::REDIS_PREFIX}:#{connection_id}"))
      conn_data['last_heartbeat'] = Time.current.to_i - 400 # 6+ minutes ago
      redis.setex("#{SseConnectionManager::REDIS_PREFIX}:#{connection_id}", 3600, conn_data.to_json)

      expect(manager.user_connection_count(user_id)).to eq(1)

      manager.cleanup_stale_connections

      expect(manager.user_connection_count(user_id)).to eq(0)
    end
  end

  describe '#stats' do
    it 'returns connection statistics' do
      manager.register_connection(1, 1, "conn-1")
      manager.register_connection(1, 1, "conn-2")
      manager.register_connection(2, 1, "conn-3")

      stats = manager.stats

      expect(stats[:total_connections]).to eq(3)
      expect(stats[:connections_by_user]).to eq({ 1 => 2, 2 => 1 })
      expect(stats[:memory_connections]).to eq(3)
    end
  end
end