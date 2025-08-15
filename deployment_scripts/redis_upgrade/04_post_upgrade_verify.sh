#!/bin/bash
# Post-Upgrade Verification Script
# Ensures Redis upgrade was successful and services are working

set -e

echo "=== Redis Post-Upgrade Verification ==="
echo ""

# 1. Redis version and basic health
echo "1. Redis Health Check:"
echo "   Version: $(redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')"
echo "   Uptime: $(redis-cli INFO server | grep uptime_in_seconds | cut -d: -f2 | tr -d '\r') seconds"
echo "   Connected clients: $(redis-cli INFO clients | grep connected_clients | cut -d: -f2 | tr -d '\r')"

# 2. Test basic Redis operations
echo ""
echo "2. Testing Redis operations:"

# Test SET/GET
redis-cli SET test:upgrade "success" > /dev/null
RESULT=$(redis-cli GET test:upgrade)
if [ "$RESULT" = "success" ]; then
    echo "   ✓ SET/GET operations working"
else
    echo "   ✗ SET/GET operations FAILED"
    exit 1
fi

# Test list operations (for Sidekiq)
redis-cli LPUSH test:list "item1" > /dev/null
redis-cli LPUSH test:list "item2" > /dev/null
LIST_LEN=$(redis-cli LLEN test:list)
if [ "$LIST_LEN" = "2" ]; then
    echo "   ✓ List operations working"
else
    echo "   ✗ List operations FAILED"
    exit 1
fi

# Cleanup test keys
redis-cli DEL test:upgrade test:list > /dev/null

# 3. Start Sidekiq
echo ""
echo "3. Starting Sidekiq..."
sudo systemctl start sidekiq

# Wait for Sidekiq to initialize
sleep 5

# 4. Test Sidekiq connectivity
echo ""
echo "4. Testing Sidekiq connectivity:"

# Check if Sidekiq can connect to Redis
if sudo systemctl is-active --quiet sidekiq; then
    echo "   ✓ Sidekiq service is running"
    
    # Check Sidekiq processes
    SIDEKIQ_PROCS=$(ps aux | grep -c "[s]idekiq" || echo "0")
    echo "   ✓ Sidekiq processes: $SIDEKIQ_PROCS"
else
    echo "   ✗ Sidekiq service FAILED to start"
    echo "   Checking logs:"
    sudo journalctl -u sidekiq -n 20
    exit 1
fi

# 5. Test application connectivity
echo ""
echo "5. Testing Rails application Redis connectivity:"

# Create a simple Rails runner script to test Redis
cat > /tmp/test_redis.rb << 'EOF'
begin
  # Test basic Redis connection
  $redis.ping
  puts "   ✓ Rails app can connect to Redis"
  
  # Test Sidekiq Redis connection
  Sidekiq.redis { |r| r.ping }
  puts "   ✓ Sidekiq can connect to Redis"
  
  # Test Redis version from app
  version = $redis.info["redis_version"]
  puts "   ✓ Redis version from app: #{version}"
  
rescue => e
  puts "   ✗ Redis connection FAILED: #{e.message}"
  exit 1
end
EOF

cd /var/www/memverse/current && bundle exec rails runner /tmp/test_redis.rb

# 6. Final status
echo ""
echo "6. Service Status Summary:"
echo "   Redis: $(systemctl is-active redis)"
echo "   Sidekiq: $(systemctl is-active sidekiq)"
echo "   Nginx: $(systemctl is-active nginx)"

# 7. Application health check
echo ""
echo "7. Application Health Check:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health_check || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo "   ✓ Application responding (HTTP $HTTP_STATUS)"
else
    echo "   ⚠ Application HTTP status: $HTTP_STATUS"
fi

echo ""
echo "=== Post-upgrade verification complete ==="
echo ""
echo "NEXT STEPS:"
echo "1. Monitor application logs: tail -f /var/www/memverse/current/log/production.log"
echo "2. Monitor Sidekiq logs: sudo journalctl -u sidekiq -f"
echo "3. Check Sentry for any new Redis-related errors"
echo "4. Test core functionality (user login, verse memorization)"

# Cleanup
rm -f /tmp/test_redis.rb