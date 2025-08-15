#!/bin/bash
# Fix Redis systemd service configuration

echo "=== Fixing Redis systemd Service ==="
echo ""

# 1. Check current systemd service
echo "1. Current systemd service status:"
sudo systemctl status redis --no-pager || true

# 2. Create proper systemd service file
echo ""
echo "2. Creating proper Redis systemd service..."
sudo tee /etc/systemd/system/redis.service << 'EOF'
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/redis-minimal.conf --supervised systemd
ExecStop=/usr/bin/redis-cli shutdown
TimeoutStopSec=0
Restart=on-failure
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

# 3. Reload systemd
echo ""
echo "3. Reloading systemd daemon..."
sudo systemctl daemon-reload

# 4. Stop any running Redis
echo ""
echo "4. Stopping any running Redis instances..."
sudo pkill -f redis-server || true
sleep 2

# 5. Start Redis via systemd
echo ""
echo "5. Starting Redis service..."
sudo systemctl start redis

# 6. Enable Redis to start on boot
echo ""
echo "6. Enabling Redis to start on boot..."
sudo systemctl enable redis

# 7. Check status
echo ""
echo "7. Checking Redis service status..."
sudo systemctl status redis --no-pager

# 8. Test Redis
echo ""
echo "8. Testing Redis connection..."
if /usr/bin/redis-cli ping; then
    echo "✓ Redis is working via systemd!"
    /usr/bin/redis-cli INFO server | grep -E "redis_version|uptime_in_seconds"
else
    echo "✗ Redis not responding"
fi

echo ""
echo "=== Systemd configuration complete ==="