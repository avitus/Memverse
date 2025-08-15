#!/bin/bash
# Redis Rollback Script
# Emergency rollback to Redis 3.2.1 if upgrade fails

set -e

echo "=== Redis Emergency Rollback Script ==="
echo "This will rollback Redis to version 3.2.1"
echo ""
read -p "Are you sure you want to rollback? (yes/no) " -n 3 -r
echo
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

# 1. Stop services
echo ""
echo "1. Stopping services..."
sudo systemctl stop sidekiq || true
sudo systemctl stop redis || true

# 2. Remove Redis 6.2
echo ""
echo "2. Removing Redis 6.2..."
if [ -f /etc/debian_version ]; then
    sudo apt-get remove -y redis-server redis-tools
else
    sudo yum remove -y redis
fi

# 3. Restore old Redis binary
echo ""
echo "3. Restoring Redis 3.2.1 binary..."
if [ -f /usr/bin/redis-server.3.2.1.backup ]; then
    sudo cp /usr/bin/redis-server.3.2.1.backup /usr/bin/redis-server
    sudo cp /usr/bin/redis-cli.3.2.1.backup /usr/bin/redis-cli
    sudo chmod +x /usr/bin/redis-server /usr/bin/redis-cli
else
    echo "ERROR: Backup binaries not found!"
    echo "You'll need to reinstall Redis 3.2.1 manually"
    exit 1
fi

# 4. Restore old configuration
echo ""
echo "4. Restoring Redis 3.2.1 configuration..."
if [ -f /etc/redis/redis.conf.3.2.1.backup ]; then
    sudo cp /etc/redis/redis.conf.3.2.1.backup /etc/redis/redis.conf
fi

# 5. Start Redis 3.2.1
echo ""
echo "5. Starting Redis 3.2.1..."
sudo systemctl start redis || sudo service redis start

# 6. Verify rollback
echo ""
echo "6. Verifying rollback..."
sleep 2

CURRENT_VERSION=$(redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')
echo "Current Redis version: $CURRENT_VERSION"

if redis-cli ping > /dev/null 2>&1; then
    echo "Redis is responding to PING"
else
    echo "ERROR: Redis is not responding!"
    exit 1
fi

# 7. Start Sidekiq
echo ""
echo "7. Starting Sidekiq..."
sudo systemctl start sidekiq

echo ""
echo "=== Rollback completed ==="
echo "Redis is now running version: $CURRENT_VERSION"
echo ""
echo "IMPORTANT: The redis-client gem issue will return!"
echo "You'll need to downgrade the gem version in Gemfile:"
echo "  gem 'redis', '~> 4.8'"
echo "Then run: bundle update redis"