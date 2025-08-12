#!/bin/bash
# Redis Troubleshooting Script
# Diagnose why Redis isn't starting after upgrade

echo "=== Redis Troubleshooting ==="
echo ""

# 1. Check Redis service status
echo "1. Redis service status:"
sudo systemctl status redis || sudo service redis status

# 2. Check Redis logs
echo ""
echo "2. Recent Redis logs:"
sudo journalctl -u redis -n 50 --no-pager || sudo tail -50 /var/log/redis/redis-server.log

# 3. Check if Redis is running on a different port or socket
echo ""
echo "3. Checking for Redis processes:"
ps aux | grep redis

# 4. Check Redis configuration file
echo ""
echo "4. Redis configuration (key settings):"
sudo grep -E "^(bind|port|protected-mode|supervised|dir|logfile)" /etc/redis/redis.conf

# 5. Check file permissions
echo ""
echo "5. Redis file permissions:"
ls -la /etc/redis/
ls -la /var/lib/redis/
ls -la /var/log/redis/

# 6. Try to start Redis manually with verbose output
echo ""
echo "6. Attempting manual start with verbose output:"
sudo redis-server /etc/redis/redis.conf --loglevel verbose 2>&1 | head -20

# 7. Check for port conflicts
echo ""
echo "7. Checking port 6379:"
sudo netstat -tlnp | grep 6379 || sudo ss -tlnp | grep 6379

# 8. Check Redis version
echo ""
echo "8. Redis binary version:"
redis-server --version

echo ""
echo "=== Troubleshooting complete ==="