#!/bin/bash
# Fix Sidekiq systemd service configuration

echo "===== FIXING SIDEKIQ SERVICE ====="
echo ""

# First, try to understand the current setup
echo "1. Current working directory structure:"
ls -la /home/avitus/memverse.com/current 2>/dev/null || echo "   /home/avitus/memverse.com/current not found"
ls -la /var/www/memverse/current 2>/dev/null || echo "   /var/www/memverse/current not found"

echo ""
echo "2. Finding correct app path..."
if [ -d "/home/avitus/memverse.com/current" ]; then
    APP_PATH="/home/avitus/memverse.com/current"
elif [ -d "/var/www/memverse/current" ]; then
    APP_PATH="/var/www/memverse/current"
else
    echo "ERROR: Cannot find Rails app directory"
    exit 1
fi
echo "   Using app path: $APP_PATH"

echo ""
echo "3. Detecting Ruby setup..."
# Check if using RVM
if [ -f "/home/deploy/.rvm/scripts/rvm" ]; then
    echo "   RVM detected for deploy user"
    RVM_SETUP="source /home/deploy/.rvm/scripts/rvm && rvm use 3.2.6"
elif [ -f "/usr/local/rvm/scripts/rvm" ]; then
    echo "   System RVM detected"
    RVM_SETUP="source /usr/local/rvm/scripts/rvm && rvm use 3.2.6"
elif [ -f "/home/avitus/.rvm/scripts/rvm" ]; then
    echo "   RVM detected for avitus user"
    RVM_SETUP="source /home/avitus/.rvm/scripts/rvm && rvm use 3.2.6"
else
    echo "   No RVM detected, using system Ruby"
    RVM_SETUP=""
fi

echo ""
echo "4. Creating updated systemd service file..."
cat << EOF > /tmp/sidekiq.service
[Unit]
Description=Sidekiq Background Jobs for Memverse
After=syslog.target network.target redis.service mysql.service

[Service]
Type=simple
WorkingDirectory=$APP_PATH

# Use the same user that owns the app files
User=avitus
Group=avitus

# Environment setup
Environment="RAILS_ENV=production"
Environment="BUNDLE_PATH=/home/avitus/memverse.com/shared/bundle"

# Start command with proper Ruby/RVM setup
ExecStart=/bin/bash -lc '${RVM_SETUP:+$RVM_SETUP && }cd $APP_PATH && bundle exec sidekiq -e production -C config/sidekiq.yml'

# Restart policy
Restart=on-failure
RestartSec=30
RestartForceExitStatus=1

# Resource limits
LimitNOFILE=65536
TimeoutStopSec=90

# Output to journal
StandardOutput=journal
StandardError=journal
SyslogIdentifier=sidekiq

# Process management
KillMode=mixed
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "5. New service file created at /tmp/sidekiq.service"
echo ""
echo "TO APPLY THE FIX:"
echo ""
echo "# 1. Backup existing service"
echo "sudo cp /etc/systemd/system/sidekiq.service /etc/systemd/system/sidekiq.service.bak"
echo ""
echo "# 2. Install new service"
echo "sudo cp /tmp/sidekiq.service /etc/systemd/system/sidekiq.service"
echo ""
echo "# 3. Reload systemd"
echo "sudo systemctl daemon-reload"
echo ""
echo "# 4. Start Sidekiq"
echo "sudo systemctl start sidekiq"
echo ""
echo "# 5. Check status"
echo "sudo systemctl status sidekiq"
echo ""
echo "# 6. Check logs"
echo "sudo journalctl -u sidekiq -f"

echo ""
echo "===== ALTERNATIVE: Run Sidekiq manually for testing ====="
echo ""
echo "cd $APP_PATH"
echo "RAILS_ENV=production bundle exec sidekiq -C config/sidekiq.yml"