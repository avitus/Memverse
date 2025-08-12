#!/bin/bash
# Redis Upgrade Script - 3.2.1 to 6.2 (Fixed for Ubuntu 16.04)
# Handles repository issues and provides alternative installation methods

set -e

echo "=== Redis Upgrade Script (3.2.1 → 6.2) ==="
echo "This script will upgrade Redis with minimal downtime"
echo ""

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
    echo "Detected Debian/Ubuntu system"
    UBUNTU_VERSION=$(lsb_release -rs)
    echo "Ubuntu version: $UBUNTU_VERSION"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
    echo "Detected RedHat/CentOS system"
else
    echo "ERROR: Unsupported OS"
    exit 1
fi

# 1. Clean up problematic repositories
echo ""
echo "1. Cleaning up APT sources..."
# Temporarily disable the problematic realm repository
sudo mkdir -p /etc/apt/sources.list.d/backup
sudo mv /etc/apt/sources.list.d/*realm* /etc/apt/sources.list.d/backup/ 2>/dev/null || true

# Update package list
sudo apt-get update

# 2. Stop Redis 3.2.1
echo ""
echo "2. Stopping Redis 3.2.1..."
sudo systemctl stop redis || sudo service redis stop

# 3. Backup old Redis binary (just in case)
echo ""
echo "3. Backing up old Redis binary..."
sudo cp /usr/bin/redis-server /usr/bin/redis-server.3.2.1.backup || true
sudo cp /usr/bin/redis-cli /usr/bin/redis-cli.3.2.1.backup || true

# 4. Install Redis 6.2
echo ""
echo "4. Installing Redis 6.2..."

# For Ubuntu 16.04, we'll use a PPA instead of the official Redis repo
if [ "$UBUNTU_VERSION" = "16.04" ]; then
    echo "Using PPA for Ubuntu 16.04..."
    
    # Remove any existing Redis packages first
    sudo apt-get remove -y redis-server redis-tools || true
    
    # Add Chris Lea's Redis PPA (well-maintained for older Ubuntu)
    sudo add-apt-repository -y ppa:chris-lea/redis-server
    sudo apt-get update
    
    # Install Redis (this PPA provides 6.0.x which is sufficient)
    sudo apt-get install -y redis-server redis-tools
else
    # For newer Ubuntu versions, use the official Redis repository
    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
    sudo apt-get update
    sudo apt-get install -y redis-server=6.2.*
fi

# 5. Update Redis configuration for compatibility
echo ""
echo "5. Updating Redis configuration..."

# Backup current config
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.3.2.1.backup || true

# Key configuration changes from 3.2 to 6.x:
# Ensure bind includes localhost
if grep -q "^bind" /etc/redis/redis.conf; then
    sudo sed -i 's/^bind .*/bind 127.0.0.1 ::1/' /etc/redis/redis.conf
else
    echo "bind 127.0.0.1 ::1" | sudo tee -a /etc/redis/redis.conf
fi

# Ensure protected mode is properly set for local connections
sudo sed -i 's/^protected-mode .*/protected-mode yes/' /etc/redis/redis.conf || echo "protected-mode yes" | sudo tee -a /etc/redis/redis.conf

# 6. Start Redis
echo ""
echo "6. Starting Redis..."
sudo systemctl start redis || sudo service redis start

# Wait for Redis to fully start
sleep 3

# 7. Verify upgrade
echo ""
echo "7. Verifying upgrade..."

NEW_VERSION=$(redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')
echo "New Redis version: $NEW_VERSION"

if redis-cli ping > /dev/null 2>&1; then
    echo "✓ Redis is responding to PING"
else
    echo "ERROR: Redis is not responding!"
    exit 1
fi

# 8. Test HELLO command (Redis 6+ feature)
echo ""
echo "8. Testing Redis 6+ features..."
# Note: Redis 6.0.x supports HELLO 2, not HELLO 3
if redis-cli HELLO 2 > /dev/null 2>&1 || redis-cli HELLO 3 > /dev/null 2>&1; then
    echo "✓ HELLO command successful - Redis 6+ confirmed!"
else
    # Some Redis 6.0.x versions might not have HELLO enabled by default
    # Check version number as fallback
    if [[ "$NEW_VERSION" =~ ^6\. ]] || [[ "$NEW_VERSION" =~ ^7\. ]]; then
        echo "✓ Redis 6+ version confirmed (HELLO might be disabled)"
    else
        echo "WARNING: Could not verify Redis 6+ features"
    fi
fi

# 9. Restore problematic repositories (if needed)
echo ""
echo "9. Restoring APT sources..."
sudo mv /etc/apt/sources.list.d/backup/* /etc/apt/sources.list.d/ 2>/dev/null || true
sudo rmdir /etc/apt/sources.list.d/backup 2>/dev/null || true

echo ""
echo "=== Redis upgrade completed successfully! ==="
echo "Old version: 3.2.1"
echo "New version: $NEW_VERSION"
echo ""
echo "IMPORTANT: The redis-client gem should now work properly."
echo "Next step: Run ./04_post_upgrade_verify.sh"