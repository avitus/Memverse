#!/bin/bash
# Script to diagnose and fix Sidekiq startup issues

echo "===== SIDEKIQ STARTUP DIAGNOSTIC ====="
echo ""

# 1. Check Ruby version
echo "1. Checking Ruby version..."
cd /home/avitus/memverse.com/current
if command -v rvm &> /dev/null; then
    echo "   RVM detected"
    rvm list
    echo "   Current Ruby:"
    ruby -v
else
    echo "   System Ruby:"
    ruby -v
fi

# 2. Check bundle
echo ""
echo "2. Checking Bundler..."
bundle -v
bundle check || echo "   Bundle check failed - run: bundle install"

# 3. Check Redis connection
echo ""
echo "3. Testing Redis connection..."
redis-cli ping || echo "   Redis connection failed"

# 4. Check permissions
echo ""
echo "4. Checking permissions..."
ls -la /home/avitus/memverse.com/current/
ls -la /home/avitus/memverse.com/shared/
ls -la /home/avitus/memverse.com/shared/log/
ls -la /home/avitus/memverse.com/shared/tmp/pids/ 2>/dev/null || mkdir -p /home/avitus/memverse.com/shared/tmp/pids/

# 5. Check for PID file issues
echo ""
echo "5. Checking for stale PID files..."
PID_FILE="/home/avitus/memverse.com/shared/tmp/pids/sidekiq.pid"
if [ -f "$PID_FILE" ]; then
    echo "   Found PID file: $PID_FILE"
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "   Process $PID is still running"
    else
        echo "   Process $PID is not running - removing stale PID file"
        rm -f $PID_FILE
    fi
else
    echo "   No PID file found"
fi

# 6. Try to load the app environment
echo ""
echo "6. Testing Rails environment..."
cd /home/avitus/memverse.com/current
sudo -u deploy bash -lc 'bundle exec rails runner "puts \"Rails loaded successfully\"; puts \"Redis: #{Sidekiq.redis {|c| c.ping}}\""' 2>&1

# 7. Check systemd service file
echo ""
echo "7. Checking systemd service configuration..."
cat /etc/systemd/system/sidekiq.service

echo ""
echo "===== SUGGESTED FIXES ====="
echo ""
echo "A. If Bundle check failed:"
echo "   cd /home/avitus/memverse.com/current"
echo "   bundle install --deployment --without development test"
echo ""
echo "B. If permissions issue:"
echo "   sudo chown -R deploy:deploy /home/avitus/memverse.com/"
echo ""
echo "C. If stale PID file:"
echo "   rm -f /home/avitus/memverse.com/shared/tmp/pids/sidekiq.pid"
echo ""
echo "D. If Ruby version mismatch:"
echo "   # Update the systemd service to use correct Ruby"
echo "   # Edit /etc/systemd/system/sidekiq.service"
echo ""
echo "E. Try alternate service configuration:"
echo "   # See fix_sidekiq_service.sh for updated service file"