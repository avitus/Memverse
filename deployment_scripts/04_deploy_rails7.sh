#!/bin/bash
# Main deployment script for Memverse Rails 7 upgrade
# This script handles the actual deployment process

set -e

# Configuration - MODIFY THESE FOR YOUR ENVIRONMENT
APP_DIR="/var/www/memverse"
APP_USER="deploy"  # User that runs the application
REPO_URL="git@github.com:avitus/Memverse.git"
BRANCH="rails-7-upgrade"
MAINTENANCE_PAGE="/var/www/maintenance.html"

# Service names (adjust based on your setup)
WEB_SERVICE="memverse-puma"
WORKER_SERVICE="memverse-sidekiq"
WEB_SERVER_SERVICE="nginx"  # or apache2

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Memverse Rails 7 Deployment"
echo "Date: $(date)"
echo "=========================================="
echo ""

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed!${NC}"
        exit 1
    fi
}

# Verify we're running as the correct user
if [ "$(whoami)" != "$APP_USER" ]; then
    echo -e "${YELLOW}Warning: Running as $(whoami), expected $APP_USER${NC}"
    echo "Switching to $APP_USER..."
    exec sudo -u "$APP_USER" "$0" "$@"
fi

# 1. Pre-deployment checks
echo "1. Running pre-deployment checks..."

# Check if backup exists
echo -n "Checking for recent backup... "
LATEST_BACKUP=$(ls -td /var/backups/memverse/rails7_upgrade_* 2>/dev/null | head -1)
if [ -z "$LATEST_BACKUP" ]; then
    echo -e "${RED}No backup found!${NC}"
    echo "Please run 02_backup_everything.sh first"
    exit 1
else
    echo -e "${GREEN}Found: $LATEST_BACKUP${NC}"
fi

# Check Ruby version
echo -n "Checking Ruby version... "
RUBY_VERSION=$(ruby -v | awk '{print $2}')
if [[ $RUBY_VERSION == 3.2.6* ]]; then
    echo -e "${GREEN}$RUBY_VERSION${NC}"
else
    echo -e "${RED}Wrong Ruby version: $RUBY_VERSION${NC}"
    echo "Please run 03_install_ruby_326.sh first"
    exit 1
fi
echo ""

# 2. Enable maintenance mode
echo "2. Enabling maintenance mode..."

# Create maintenance page if it doesn't exist
if [ ! -f "$MAINTENANCE_PAGE" ]; then
    cat > "$MAINTENANCE_PAGE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Memverse - Maintenance in Progress</title>
    <meta charset="utf-8">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px;
            background-color: #f0f0f0;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            max-width: 600px;
            margin: 0 auto;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        p { color: #666; line-height: 1.6; }
        .eta { 
            background: #f8f8f8; 
            padding: 20px; 
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Memverse is Currently Under Maintenance</h1>
        <p>We're upgrading our system to provide you with better performance and new features.</p>
        <div class="eta">
            <strong>Estimated completion time: 30-45 minutes</strong>
        </div>
        <p>We apologize for any inconvenience. Your verses and progress are safe!</p>
        <p>Start time: <span id="start-time"></span></p>
    </div>
    <script>
        document.getElementById('start-time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF
fi

# Configure web server for maintenance mode
echo "Configuring web server for maintenance mode..."
if systemctl is-active --quiet nginx; then
    # Create Nginx maintenance config
    sudo tee /etc/nginx/sites-available/maintenance > /dev/null << EOF
server {
    listen 80;
    server_name _;
    root /var/www;
    
    location / {
        if (-f \$document_root/maintenance.html) {
            return 503;
        }
    }
    
    error_page 503 @maintenance;
    location @maintenance {
        rewrite ^.*$ /maintenance.html break;
    }
}
EOF
    
    # Enable maintenance mode
    sudo ln -sf /etc/nginx/sites-available/maintenance /etc/nginx/sites-enabled/
    sudo nginx -s reload
    check_status "Maintenance mode enabled"
fi
echo ""

# 3. Stop application services
echo "3. Stopping application services..."

echo "Stopping Sidekiq workers gracefully..."
sudo systemctl stop "$WORKER_SERVICE" || true
sleep 5  # Give workers time to finish current jobs

echo "Stopping web server..."
sudo systemctl stop "$WEB_SERVICE" || true

check_status "Services stopped"
echo ""

# 4. Deploy new code
echo "4. Deploying new code..."
cd "$APP_DIR"

# Save current branch/commit for rollback
PREVIOUS_COMMIT=$(git rev-parse HEAD)
PREVIOUS_BRANCH=$(git branch --show-current)
echo "Current commit: $PREVIOUS_COMMIT"
echo "Current branch: $PREVIOUS_BRANCH"

# Fetch and checkout new code
echo "Fetching latest code..."
git fetch origin
check_status "Git fetch"

echo "Checking out $BRANCH..."
git checkout "$BRANCH"
check_status "Git checkout"

echo "Pulling latest changes..."
git pull origin "$BRANCH"
check_status "Git pull"

NEW_COMMIT=$(git rev-parse HEAD)
echo "New commit: $NEW_COMMIT"
echo ""

# 5. Install dependencies
echo "5. Installing dependencies..."

echo "Installing Ruby gems..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install --jobs=4
check_status "Bundle install"

echo "Installing JavaScript dependencies..."
npm ci --production
check_status "NPM install"
echo ""

# 6. Run database migrations
echo "6. Running database migrations..."

# Check pending migrations
echo "Checking for pending migrations..."
PENDING=$(bundle exec rails db:migrate:status | grep "down" || true)
if [ -n "$PENDING" ]; then
    echo "Pending migrations found:"
    echo "$PENDING"
    
    # Run migrations
    echo "Running migrations..."
    RAILS_ENV=production bundle exec rails db:migrate
    check_status "Database migrations"
    
    # Special handling for Active Storage migration
    if echo "$PENDING" | grep -q "create_active_storage"; then
        echo -e "${YELLOW}Active Storage tables created. File migration may be needed.${NC}"
    fi
    
    # Special handling for Paperclip removal
    if echo "$PENDING" | grep -q "remove_paperclip"; then
        echo -e "${YELLOW}Paperclip columns removed. Ensure file migration is complete!${NC}"
    fi
else
    echo "No pending migrations."
fi
echo ""

# 7. Compile assets
echo "7. Compiling assets..."
RAILS_ENV=production bundle exec rails assets:precompile
check_status "Asset compilation"

# Clean old assets
echo "Cleaning old assets..."
RAILS_ENV=production bundle exec rails assets:clean
check_status "Asset cleanup"
echo ""

# 8. Update file permissions
echo "8. Setting file permissions..."
chmod -R 755 "$APP_DIR"
find "$APP_DIR/public" -type f -exec chmod 644 {} \;
find "$APP_DIR/log" -type f -exec chmod 666 {} \;
find "$APP_DIR/tmp" -type d -exec chmod 777 {} \;
check_status "File permissions"
echo ""

# 9. Clear caches
echo "9. Clearing caches..."
RAILS_ENV=production bundle exec rails r "Rails.cache.clear"
check_status "Rails cache cleared"

# Clear Redis cache if used
if command -v redis-cli &> /dev/null; then
    echo "Flushing Redis cache..."
    redis-cli FLUSHDB
    check_status "Redis cache cleared"
fi
echo ""

# 10. Start services
echo "10. Starting services..."

echo "Starting web server..."
sudo systemctl start "$WEB_SERVICE"
check_status "Web server started"

echo "Starting Sidekiq..."
sudo systemctl start "$WORKER_SERVICE"
check_status "Sidekiq started"

# Wait for services to be ready
echo "Waiting for services to stabilize..."
sleep 10
echo ""

# 11. Health checks
echo "11. Running health checks..."

# Check if web server is responding
echo -n "Checking web server response... "
if curl -f -s -o /dev/null http://localhost/; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}Failed!${NC}"
    echo "Web server is not responding correctly"
fi

# Check if Rails is running
echo -n "Checking Rails application... "
if curl -f -s -o /dev/null http://localhost/health_check 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Health check endpoint not found (this may be normal)${NC}"
fi

# Check Sidekiq
echo -n "Checking Sidekiq status... "
if systemctl is-active --quiet "$WORKER_SERVICE"; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Not running!${NC}"
fi
echo ""

# 12. Disable maintenance mode
echo "12. Disabling maintenance mode..."
if [ -f "$MAINTENANCE_PAGE" ]; then
    sudo rm -f "$MAINTENANCE_PAGE"
fi

if systemctl is-active --quiet nginx; then
    sudo rm -f /etc/nginx/sites-enabled/maintenance
    sudo nginx -s reload
    check_status "Maintenance mode disabled"
fi
echo ""

# 13. Post-deployment tasks
echo "13. Running post-deployment tasks..."

# Log deployment
cat >> "$APP_DIR/log/deployments.log" << EOF
Deployment completed: $(date)
Previous commit: $PREVIOUS_COMMIT ($PREVIOUS_BRANCH)
New commit: $NEW_COMMIT ($BRANCH)
Ruby version: $(ruby -v)
Rails version: $(bundle exec rails -v)
EOF

# Warm up the application
echo "Warming up application..."
curl -s http://localhost/ > /dev/null || true
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}Deployment Completed Successfully!${NC}"
echo "=========================================="
echo "Deployed commit: $NEW_COMMIT"
echo "Ruby version: $(ruby -v)"
echo "Rails version: $(bundle exec rails -v)"
echo ""
echo "Next steps:"
echo "1. Run post-deployment verification: ./05_post_deployment_verify.sh"
echo "2. Monitor application logs: tail -f $APP_DIR/log/production.log"
echo "3. Check error tracking (Sentry/Airbrake)"
echo "4. Monitor performance metrics"
echo ""
echo -e "${YELLOW}If issues occur, run rollback script: ./06_rollback.sh${NC}"