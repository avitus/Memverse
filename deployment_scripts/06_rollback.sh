#!/bin/bash
# Emergency rollback script for Memverse Rails 7 deployment
# Use this if the deployment encounters critical issues

set -e

# Configuration
APP_DIR="/var/www/memverse"
APP_USER="deploy"
PREVIOUS_BRANCH="upgrade-2026"  # The branch to rollback to
MAINTENANCE_PAGE="/var/www/maintenance.html"

# Service names
WEB_SERVICE="memverse-puma"
WORKER_SERVICE="memverse-sidekiq"
WEB_SERVER_SERVICE="nginx"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo -e "${RED}MEMVERSE EMERGENCY ROLLBACK${NC}"
echo "Date: $(date)"
echo "=========================================="
echo ""
echo -e "${YELLOW}This will rollback the Rails 7 deployment!${NC}"
echo ""

# Confirmation
read -p "Are you sure you want to rollback? Type 'ROLLBACK' to confirm: " CONFIRM
if [ "$CONFIRM" != "ROLLBACK" ]; then
    echo "Rollback cancelled."
    exit 1
fi

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed!${NC}"
        # Don't exit on failure during rollback
    fi
}

# 1. Enable maintenance mode
echo ""
echo "1. Enabling maintenance mode..."

# Create emergency maintenance page
cat > "$MAINTENANCE_PAGE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Memverse - Emergency Maintenance</title>
    <meta charset="utf-8">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px;
            background-color: #fff3cd;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            max-width: 600px;
            margin: 0 auto;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border: 2px solid #ffc107;
        }
        h1 { color: #856404; }
        p { color: #666; line-height: 1.6; }
        .notice { 
            background: #fff3cd; 
            padding: 20px; 
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #ffeaa7;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Emergency Maintenance in Progress</h1>
        <div class="notice">
            <strong>We encountered an issue during our system upgrade.</strong>
        </div>
        <p>Our team is working to restore normal service as quickly as possible.</p>
        <p>Your verses and progress are safe. We'll be back online shortly!</p>
        <p>Start time: <span id="start-time"></span></p>
    </div>
    <script>
        document.getElementById('start-time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

# Enable maintenance mode in web server
if systemctl is-active --quiet nginx; then
    sudo ln -sf /etc/nginx/sites-available/maintenance /etc/nginx/sites-enabled/
    sudo nginx -s reload
    check_status "Maintenance mode enabled"
fi

# 2. Stop services
echo ""
echo "2. Stopping all services..."

sudo systemctl stop "$WORKER_SERVICE" || true
sudo systemctl stop "$WEB_SERVICE" || true

check_status "Services stopped"
sleep 5

# 3. Find backup
echo ""
echo "3. Locating backup..."

LATEST_BACKUP=$(ls -td /var/backups/memverse/rails7_upgrade_* 2>/dev/null | head -1)
if [ -z "$LATEST_BACKUP" ]; then
    echo -e "${RED}ERROR: No backup found!${NC}"
    echo "Cannot proceed with automated rollback without backup."
    echo "Manual intervention required!"
    exit 1
else
    echo "Found backup: $LATEST_BACKUP"
fi

# Get deployment info
if [ -f "$APP_DIR/log/deployments.log" ]; then
    echo ""
    echo "Last deployment info:"
    tail -5 "$APP_DIR/log/deployments.log"
fi

# 4. Rollback code
echo ""
echo "4. Rolling back application code..."
cd "$APP_DIR"

# Save current state for debugging
FAILED_COMMIT=$(git rev-parse HEAD)
echo "Failed deployment commit: $FAILED_COMMIT"

# Stash any local changes
git stash push -m "Rollback stash $(date +%Y%m%d_%H%M%S)"

# Checkout previous branch
echo "Checking out $PREVIOUS_BRANCH..."
git fetch origin
git checkout "$PREVIOUS_BRANCH"
git pull origin "$PREVIOUS_BRANCH"

check_status "Code rollback"

# 5. Rollback Ruby version if needed
echo ""
echo "5. Checking Ruby version..."

CURRENT_RUBY=$(ruby -v | awk '{print $2}')
REQUIRED_RUBY=$(grep "ruby " Gemfile | grep -o '"[^"]*"' | tr -d '"')

echo "Current Ruby: $CURRENT_RUBY"
echo "Required Ruby: $REQUIRED_RUBY"

if [[ "$CURRENT_RUBY" != "$REQUIRED_RUBY"* ]]; then
    echo "Switching Ruby version to $REQUIRED_RUBY..."
    if command -v rvm &> /dev/null; then
        rvm use "$REQUIRED_RUBY"
    elif command -v rbenv &> /dev/null; then
        rbenv local "$REQUIRED_RUBY"
        rbenv rehash
    fi
    check_status "Ruby version switch"
fi

# 6. Restore gems
echo ""
echo "6. Restoring gem dependencies..."

# Remove Gemfile.lock to ensure clean state
rm -f Gemfile.lock

# Install gems for the rolled-back version
bundle install --deployment --without development test
check_status "Gem restoration"

# 7. Rollback database if needed
echo ""
echo "7. Checking database state..."

# Check if we need to rollback migrations
CURRENT_VERSION=$(bundle exec rails db:version | grep "Current version:" | awk '{print $3}')
TARGET_VERSION=$(cat "$LATEST_BACKUP/database/migration_version.txt" 2>/dev/null || echo "unknown")

echo "Current DB version: $CURRENT_VERSION"
echo "Target DB version: $TARGET_VERSION"

if [ "$CURRENT_VERSION" != "$TARGET_VERSION" ] && [ "$TARGET_VERSION" != "unknown" ]; then
    echo -e "${YELLOW}Database migration rollback needed${NC}"
    echo "This requires manual intervention!"
    echo ""
    echo "To rollback database:"
    echo "1. Stop all services"
    echo "2. Restore database from backup:"
    echo "   gunzip < $LATEST_BACKUP/database/*_full.sql.gz | mysql -u root -p"
    echo "3. Verify migration version matches"
    
    read -p "Have you restored the database? (yes/no): " DB_RESTORED
    if [ "$DB_RESTORED" != "yes" ]; then
        echo -e "${RED}Database not restored. Manual intervention required!${NC}"
    fi
fi

# 8. Restore file uploads if needed
echo ""
echo "8. Checking file uploads..."

if [ -f "$LATEST_BACKUP/files/paperclip_uploads.tar.gz" ]; then
    read -p "Restore Paperclip uploads from backup? (yes/no): " RESTORE_FILES
    if [ "$RESTORE_FILES" = "yes" ]; then
        echo "Restoring uploads..."
        tar -xzf "$LATEST_BACKUP/files/paperclip_uploads.tar.gz" -C "$APP_DIR/public"
        check_status "File restoration"
    fi
fi

# 9. Compile assets
echo ""
echo "9. Compiling assets for rolled-back version..."

RAILS_ENV=production bundle exec rake assets:precompile
check_status "Asset compilation"

# 10. Clear caches
echo ""
echo "10. Clearing all caches..."

RAILS_ENV=production bundle exec rails r "Rails.cache.clear" || true
redis-cli FLUSHDB || true

check_status "Cache clearing"

# 11. Start services
echo ""
echo "11. Starting services..."

sudo systemctl start "$WEB_SERVICE"
check_status "Web service start"

sudo systemctl start "$WORKER_SERVICE"
check_status "Worker service start"

sleep 10

# 12. Verify services
echo ""
echo "12. Verifying services..."

if systemctl is-active --quiet "$WEB_SERVICE"; then
    echo -e "${GREEN}Web service is running${NC}"
else
    echo -e "${RED}Web service failed to start!${NC}"
fi

if systemctl is-active --quiet "$WORKER_SERVICE"; then
    echo -e "${GREEN}Worker service is running${NC}"
else
    echo -e "${RED}Worker service failed to start!${NC}"
fi

# 13. Quick health check
echo ""
echo "13. Running quick health check..."

if curl -f -s -o /dev/null http://localhost/; then
    echo -e "${GREEN}Application is responding${NC}"
else
    echo -e "${RED}Application is not responding!${NC}"
fi

# 14. Disable maintenance mode
echo ""
echo "14. Disabling maintenance mode..."

sudo rm -f "$MAINTENANCE_PAGE"
if systemctl is-active --quiet nginx; then
    sudo rm -f /etc/nginx/sites-enabled/maintenance
    sudo nginx -s reload
    check_status "Maintenance mode disabled"
fi

# 15. Create rollback report
echo ""
echo "15. Creating rollback report..."

REPORT_FILE="$APP_DIR/rollback_report_$(date +%Y%m%d_%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
Memverse Rollback Report
========================
Date: $(date)

Rollback Details:
- Failed commit: $FAILED_COMMIT
- Rolled back to: $(git rev-parse HEAD)
- Branch: $(git branch --show-current)
- Ruby version: $(ruby -v)
- Rails version: $(bundle exec rails -v)

Service Status:
- Web service: $(systemctl is-active $WEB_SERVICE)
- Worker service: $(systemctl is-active $WORKER_SERVICE)
- Redis: $(redis-cli ping 2>/dev/null || echo "Not responding")

Recent Errors:
$(tail -50 $APP_DIR/log/production.log | grep -i error | tail -10)

Actions Taken:
✓ Code rolled back to $PREVIOUS_BRANCH
✓ Dependencies restored
✓ Assets recompiled
✓ Services restarted
$([ "$DB_RESTORED" = "yes" ] && echo "✓ Database restored from backup")

Manual Actions Required:
- Verify all critical features are working
- Check error monitoring
- Notify team of rollback
- Investigate root cause of deployment failure
EOF

echo "Rollback report saved to: $REPORT_FILE"

# Final summary
echo ""
echo "=========================================="
echo -e "${YELLOW}ROLLBACK COMPLETED${NC}"
echo "=========================================="
echo "The application has been rolled back to the previous version."
echo ""
echo -e "${RED}IMPORTANT POST-ROLLBACK TASKS:${NC}"
echo "1. Test critical functionality immediately"
echo "2. Monitor logs: tail -f $APP_DIR/log/production.log"
echo "3. Check error tracking service"
echo "4. Notify your team about the rollback"
echo "5. Create incident report"
echo ""
echo "Failed deployment artifacts:"
echo "- Commit: $FAILED_COMMIT"
echo "- Backup: $LATEST_BACKUP"
echo ""
echo "To investigate the failure:"
echo "1. Check deployment logs"
echo "2. Review error logs from the failed deployment"
echo "3. Test the failed deployment in staging environment"
echo ""
echo -e "${YELLOW}Remember to plan fixes before attempting deployment again!${NC}"