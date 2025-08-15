#!/bin/bash
# Fix Redis path issue - system using old Redis binary

echo "=== Fixing Redis Path Issue ==="
echo ""

# 1. Check where Redis binaries are installed
echo "1. Locating Redis binaries..."
echo "Old Redis 3.2.1 location:"
ls -la /usr/local/bin/redis* 2>/dev/null || echo "Not found in /usr/local/bin"

echo ""
echo "New Redis 7.0.11 location:"
ls -la /usr/bin/redis* 2>/dev/null || echo "Not found in /usr/bin"

# 2. Stop any running Redis
echo ""
echo "2. Stopping all Redis instances..."
sudo systemctl stop redis 2>/dev/null || true
sudo service redis stop 2>/dev/null || true
sudo pkill -f redis-server 2>/dev/null || true

# 3. Disable old Redis from starting
echo ""
echo "3. Backing up old Redis binaries..."
sudo mv /usr/local/bin/redis-server /usr/local/bin/redis-server.old 2>/dev/null || true
sudo mv /usr/local/bin/redis-cli /usr/local/bin/redis-cli.old 2>/dev/null || true

# 4. Update systemd service file to use correct path
echo ""
echo "4. Checking systemd service file..."
if [ -f /etc/systemd/system/redis.service ]; then
    echo "Custom systemd service found. Updating..."
    sudo cp /etc/systemd/system/redis.service /etc/systemd/system/redis.service.backup
    
    # Update paths in service file
    sudo sed -i 's|/usr/local/bin/redis-server|/usr/bin/redis-server|g' /etc/systemd/system/redis.service
    sudo sed -i 's|/usr/local/bin/redis-cli|/usr/bin/redis-cli|g' /etc/systemd/system/redis.service
else
    echo "Using default systemd service"
fi

# 5. Create minimal working config
echo ""
echo "5. Creating minimal Redis 7.0 config..."
sudo tee /etc/redis/redis-minimal.conf << 'EOF'
# Minimal Redis configuration for Memverse
bind 127.0.0.1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16
save ""
stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
maxmemory-policy allkeys-lru
appendonly no
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
EOF

# 6. Set proper permissions
echo ""
echo "6. Setting permissions..."
sudo chown redis:redis /etc/redis/redis-minimal.conf
sudo chmod 640 /etc/redis/redis-minimal.conf
sudo mkdir -p /var/run/redis /var/lib/redis /var/log/redis
sudo chown -R redis:redis /var/run/redis /var/lib/redis /var/log/redis

# 7. Check disk space
echo ""
echo "7. Checking disk space..."
df -h /var/lib/redis

# 8. Clean up old Redis data if needed
echo ""
echo "8. Cleaning up old Redis data..."
sudo rm -f /var/lib/redis/dump.rdb.old 2>/dev/null || true

# 9. Reload systemd and start Redis
echo ""
echo "9. Starting Redis 7.0..."
sudo systemctl daemon-reload
sudo /usr/bin/redis-server /etc/redis/redis-minimal.conf --daemonize yes

# 10. Verify
echo ""
echo "10. Verifying Redis..."
sleep 2
echo "Redis version:"
/usr/bin/redis-cli --version
echo ""
echo "Redis ping test:"
if /usr/bin/redis-cli ping; then
    echo "✓ Redis is running!"
    echo ""
    echo "Redis info:"
    /usr/bin/redis-cli INFO server | grep -E "redis_version|tcp_port|process_id"
else
    echo "✗ Redis still not responding"
    echo "Checking process:"
    ps aux | grep redis
fi

echo ""
echo "=== Fix complete ==="
echo ""
echo "Next steps:"
echo "1. Update systemd to manage Redis properly:"
echo "   sudo systemctl stop redis"
echo "   sudo systemctl start redis"
echo "2. Run the post-upgrade verification script"