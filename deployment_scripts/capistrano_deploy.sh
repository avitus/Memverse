#!/bin/bash
# Capistrano-based deployment script for Memverse Rails 7 upgrade
# This script uses Capistrano for the actual deployment

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LOG_FILE="rails7_deployment_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "Memverse Rails 7 Deployment (Capistrano)"
echo "=========================================="
echo ""

# Function to run cap command with logging
run_cap() {
    local command="$1"
    echo ""
    echo -e "${BLUE}Running: cap production $command${NC}"
    echo "=========================================="
    
    if bundle exec cap production "$command" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✓ Success${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
}

# Pre-flight checks
echo "Pre-deployment Checklist:"
echo "------------------------"
echo "[ ] Production server has MySQL 5.7+ or MariaDB 10.2+"
echo "[ ] Ruby 3.2.6 is installed on production"
echo "[ ] Recent backup exists"
echo "[ ] Capistrano can connect to production"
echo "[ ] You have reviewed the changes between branches"
echo ""

read -p "Have all items been verified? (yes/no): " VERIFIED
if [ "$VERIFIED" != "yes" ]; then
    echo "Please complete all checklist items before proceeding."
    exit 1
fi

# Test Capistrano connection
echo ""
echo "Testing Capistrano connection..."
if bundle exec cap production deploy:check 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${GREEN}✓ Capistrano connection successful${NC}"
else
    echo -e "${RED}✗ Capistrano connection failed${NC}"
    echo "Please check your SSH keys and server configuration."
    exit 1
fi

# Main deployment process
echo ""
echo -e "${YELLOW}Starting Rails 7 deployment process...${NC}"
echo "This will:"
echo "1. Check prerequisites on production"
echo "2. Create a comprehensive backup"
echo "3. Enable maintenance mode"
echo "4. Deploy Rails 7 code"
echo "5. Run migrations"
echo "6. Verify deployment"
echo ""

read -p "Continue with deployment? (yes/no): " CONTINUE
if [ "$CONTINUE" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 1: Check prerequisites
echo ""
echo "Step 1: Checking Prerequisites"
echo "=============================="
if ! run_cap "rails7:check_prerequisites"; then
    echo -e "${RED}Prerequisites not met!${NC}"
    echo "Please install Ruby 3.2.6 on production first:"
    echo "  cap production rails7:install_ruby"
    exit 1
fi

# Step 2: Create backup
echo ""
echo "Step 2: Creating Backup"
echo "======================"
echo -e "${YELLOW}This step is critical - do not skip!${NC}"
read -p "Create backup? (yes/no): " CREATE_BACKUP
if [ "$CREATE_BACKUP" = "yes" ]; then
    if ! run_cap "rails7:backup"; then
        echo -e "${RED}Backup failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}WARNING: Proceeding without backup is extremely risky!${NC}"
    read -p "Are you SURE? Type 'SKIP BACKUP' to continue: " SKIP
    if [ "$SKIP" != "SKIP BACKUP" ]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

# Step 3: Deploy Rails 7
echo ""
echo "Step 3: Deploying Rails 7"
echo "========================"
echo -e "${RED}This will cause downtime!${NC}"
echo ""

# Show what will happen
echo "The deployment will:"
echo "- Enable maintenance mode"
echo "- Deploy code from rails-7-upgrade branch"
echo "- Run database migrations"
echo "- Compile assets"
echo "- Restart services"
echo "- Disable maintenance mode"
echo ""

read -p "Ready to deploy? (yes/no): " DEPLOY
if [ "$DEPLOY" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Monitor in another terminal
echo ""
echo -e "${BLUE}TIP: Monitor the deployment in another terminal:${NC}"
echo "  ssh production-server"
echo "  tail -f /home/avitus/memverse.com/current/log/production.log"
echo ""
echo "Press Enter when ready to continue..."
read

# Run the deployment
if ! run_cap "rails7:deploy"; then
    echo ""
    echo -e "${RED}Deployment failed!${NC}"
    echo ""
    echo "To rollback:"
    echo "1. Automatic: cap production rails7:rollback_emergency"
    echo "2. Manual: cap production deploy:rollback"
    echo ""
    echo "Check logs for details: $LOG_FILE"
    exit 1
fi

# Step 4: Post-deployment verification
echo ""
echo "Step 4: Post-Deployment Verification"
echo "===================================="
if ! run_cap "rails7:verify"; then
    echo -e "${YELLOW}Some verification checks failed${NC}"
    echo "Please investigate before considering deployment complete."
fi

# Additional manual checks
echo ""
echo "Step 5: Manual Verification"
echo "=========================="
echo "Please manually verify:"
echo ""
echo "1. Visit the website and check key pages:"
echo "   - Homepage"
echo "   - Login page"
echo "   - Verse memorization"
echo "   - File uploads"
echo ""
echo "2. Check background jobs:"
echo "   cap production sidekiq:stats"
echo ""
echo "3. Monitor logs:"
echo "   cap production logs:tail"
echo ""
echo "4. Check error tracking (Sentry/Airbrake)"
echo ""

# Summary
echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Process Complete!${NC}"
echo "=========================================="
echo ""
echo "Deployment log: $LOG_FILE"
echo ""
echo "Useful commands:"
echo "- Check status: cap production deploy:status"
echo "- View logs: cap production logs:tail"
echo "- Rollback: cap production deploy:rollback"
echo "- Emergency rollback: cap production rails7:rollback_emergency"
echo ""
echo "If everything looks good, update the production branch:"
echo "  git checkout master"
echo "  git merge rails-7-upgrade"
echo "  git push origin master"
echo ""
echo "Then update Capistrano deployment branch in config/deploy/production.rb"