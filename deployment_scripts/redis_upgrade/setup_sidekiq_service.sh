#!/bin/bash
# Setup Sidekiq service for Memverse

echo "=== Setting up Sidekiq Service ==="
echo ""

# 1. Find Sidekiq processes
echo "1. Checking for running Sidekiq processes..."
ps aux | grep -E "[s]idekiq|[b]undle.*sidekiq" || echo "No Sidekiq processes found"

# 2. Locate Rails app
echo ""
echo "2. Locating Rails application..."
RAILS_ROOT="/var/www/memverse/current"
if [ -d "$RAILS_ROOT" ]; then
    echo "Found Rails app at: $RAILS_ROOT"
else
    # Try alternative locations
    for dir in /home/*/memverse /var/www/memverse /opt/memverse; do
        if [ -d "$dir" ] && [ -f "$dir/Gemfile" ]; then
            RAILS_ROOT="$dir"
            echo "Found Rails app at: $RAILS_ROOT"
            break
        fi
    done
fi

# 3. Create Sidekiq systemd service
echo ""
echo "3. Creating Sidekiq systemd service..."
sudo tee /etc/systemd/system/sidekiq.service << EOF
[Unit]
Description=Sidekiq Background Jobs for Memverse
After=syslog.target network.target redis.service

[Service]
Type=simple
WorkingDirectory=$RAILS_ROOT
ExecStart=/bin/bash -lc 'bundle exec sidekiq -e production'
User=deploy
Group=deploy
UMask=0002

# Restart policy
Restart=on-failure
RestartSec=15

# Output to journal
StandardOutput=journal
StandardError=journal

# This will default to "bundler" if we don't set it
SyslogIdentifier=sidekiq

[Install]
WantedBy=multi-user.target
EOF

# 4. Reload systemd
echo ""
echo "4. Reloading systemd..."
sudo systemctl daemon-reload

# 5. Start Sidekiq
echo ""
echo "5. Starting Sidekiq service..."
sudo systemctl start sidekiq

# 6. Enable Sidekiq to start on boot
echo ""
echo "6. Enabling Sidekiq to start on boot..."
sudo systemctl enable sidekiq

# 7. Check status
echo ""
echo "7. Checking Sidekiq status..."
sleep 3
sudo systemctl status sidekiq --no-pager

# 8. Check logs
echo ""
echo "8. Recent Sidekiq logs:"
sudo journalctl -u sidekiq -n 20 --no-pager

echo ""
echo "=== Sidekiq setup complete ==="
echo ""
echo "Monitor Sidekiq with:"
echo "  sudo journalctl -u sidekiq -f"
echo "  sudo systemctl status sidekiq"