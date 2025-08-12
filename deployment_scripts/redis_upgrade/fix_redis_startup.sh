#!/bin/bash
# Fix Redis startup issues after upgrade

echo "=== Fixing Redis Startup Issues ==="
echo ""

# 1. Fix permissions on Redis config
echo "1. Fixing config file permissions..."
sudo chown redis:redis /etc/redis/redis.conf
sudo chmod 640 /etc/redis/redis.conf

# 2. Create necessary directories with correct ownership
echo "2. Ensuring Redis directories exist with correct permissions..."
sudo mkdir -p /var/lib/redis
sudo mkdir -p /var/log/redis
sudo mkdir -p /var/run/redis
sudo chown -R redis:redis /var/lib/redis /var/log/redis /var/run/redis

# 3. Update Redis config for Redis 7.0 compatibility
echo "3. Updating Redis configuration..."

# Backup current config
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.backup

# Key settings for Redis 7.0
sudo tee /etc/redis/redis.conf.minimal << 'EOF'
# Minimal Redis 7.0 configuration for Memverse

# Network
bind 127.0.0.1 ::1
protected-mode yes
port 6379

# General
daemonize yes
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log

# Persistence (minimal for Sidekiq)
save ""
appendonly no

# Working directory
dir /var/lib/redis

# Memory
maxmemory-policy allkeys-lru

# Clients
timeout 0
tcp-keepalive 300

# Security
# requirepass yourpassword  # Uncomment and set if needed
EOF

# 4. Use minimal config temporarily
echo "4. Using minimal configuration..."
sudo mv /etc/redis/redis.conf /etc/redis/redis.conf.full
sudo mv /etc/redis/redis.conf.minimal /etc/redis/redis.conf
sudo chown redis:redis /etc/redis/redis.conf
sudo chmod 640 /etc/redis/redis.conf

# 5. Restart Redis
echo "5. Starting Redis with minimal config..."
sudo systemctl daemon-reload
sudo systemctl start redis || sudo service redis start

# 6. Test Redis
echo "6. Testing Redis..."
sleep 2
if redis-cli ping; then
    echo "✓ Redis is now running!"
    redis-cli INFO server | grep redis_version
else
    echo "✗ Redis still not responding"
    echo "Checking logs:"
    sudo tail -20 /var/log/redis/redis-server.log
fi

echo ""
echo "=== Fix attempt complete ==="
echo ""
echo "If Redis is now running, you can:"
echo "1. Keep the minimal config (recommended for Sidekiq)"
echo "2. Merge settings from /etc/redis/redis.conf.full if needed"