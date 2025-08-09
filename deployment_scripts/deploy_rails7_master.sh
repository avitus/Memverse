#!/bin/bash
# Master deployment script for Memverse Rails 7 upgrade
# This script orchestrates the entire deployment process

set -e

# Configuration
SCRIPT_DIR="$(dirname "$0")"
LOG_FILE="/var/log/memverse_rails7_deployment_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure all scripts are executable
chmod +x "$SCRIPT_DIR"/*.sh

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to run a script with logging
run_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}Running: $script_name${NC}"
    echo -e "${BLUE}=========================================${NC}"
    
    if [ -f "$script_path" ]; then
        log "Starting $script_name"
        if bash "$script_path" 2>&1 | tee -a "$LOG_FILE"; then
            log "✓ $script_name completed successfully"
            return 0
        else
            log "✗ $script_name failed!"
            return 1
        fi
    else
        echo -e "${RED}Script not found: $script_path${NC}"
        return 1
    fi
}

# Main deployment process
clear
cat << 'EOF'
  __  __                                         
 |  \/  | ___ _ __ _____   _____ _ __ ___  ___  
 | |\/| |/ _ \ '_ ` _ \ \ / / _ \ '__/ __|/ _ \ 
 | |  | |  __/ | | | | \ V /  __/ |  \__ \  __/ 
 |_|  |_|\___|_| |_| |_|\_/ \___|_|  |___/\___| 
                                                 
        Rails 7 Deployment Process
        
EOF

echo "This master script will guide you through the entire"
echo "Rails 7 deployment process for Memverse."
echo ""
echo "Deployment log: $LOG_FILE"
echo ""
echo -e "${YELLOW}WARNING: This is a major upgrade!${NC}"
echo "- Ruby 2.7.8 → 3.2.6"
echo "- Rails 5.x → 7.0"
echo "- Multiple dependency changes"
echo ""
read -p "Have you read all the deployment documentation? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Please review the documentation before proceeding."
    exit 1
fi

log "Starting Memverse Rails 7 deployment process"

# Step 0: MySQL compatibility check
echo ""
echo -e "${BLUE}Step 0: MySQL Compatibility Check${NC}"
echo "=================================="
read -p "Run MySQL compatibility check? (yes/no): " RUN_STEP
if [ "$RUN_STEP" = "yes" ]; then
    if ! run_script "00_mysql_upgrade_check.sh"; then
        echo -e "${RED}MySQL compatibility check failed!${NC}"
        echo "Please resolve MySQL issues before proceeding."
        exit 1
    fi
fi

# Step 1: Pre-deployment verification
echo ""
echo -e "${BLUE}Step 1: Pre-deployment Verification${NC}"
echo "===================================="
echo "This will check if your server meets all requirements."
read -p "Run pre-deployment verification? (yes/no): " RUN_STEP
if [ "$RUN_STEP" = "yes" ]; then
    if ! run_script "01_pre_deployment_check.sh"; then
        echo -e "${RED}Pre-deployment checks failed!${NC}"
        echo "Please resolve all issues before proceeding."
        exit 1
    fi
fi

# Step 2: Backup
echo ""
echo -e "${BLUE}Step 2: Complete System Backup${NC}"
echo "==============================="
echo "This will create a complete backup of your system."
echo -e "${YELLOW}This step is CRITICAL - do not skip!${NC}"
read -p "Create backup? (yes/no): " RUN_STEP
if [ "$RUN_STEP" = "yes" ]; then
    if ! run_script "02_backup_everything.sh"; then
        echo -e "${RED}Backup failed!${NC}"
        echo "Cannot proceed without a successful backup."
        exit 1
    fi
else
    echo -e "${RED}WARNING: Proceeding without backup is extremely risky!${NC}"
    read -p "Are you SURE you want to continue without backup? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

# Step 3: Install Ruby 3.2.6
echo ""
echo -e "${BLUE}Step 3: Install Ruby 3.2.6${NC}"
echo "=========================="
echo "This will install Ruby 3.2.6 using your Ruby version manager."
read -p "Install Ruby 3.2.6? (yes/no): " RUN_STEP
if [ "$RUN_STEP" = "yes" ]; then
    if ! run_script "03_install_ruby_326.sh"; then
        echo -e "${RED}Ruby installation failed!${NC}"
        exit 1
    fi
fi

# Checkpoint
echo ""
echo -e "${YELLOW}=== CHECKPOINT ===${NC}"
echo "Before proceeding with the actual deployment:"
echo "1. Have you verified the backup is complete and valid?"
echo "2. Is Ruby 3.2.6 installed and working?"
echo "3. Are you ready for application downtime?"
echo "4. Do you have the rollback script ready?"
echo ""
read -p "Continue with deployment? (yes/no): " CONTINUE
if [ "$CONTINUE" != "yes" ]; then
    echo "Deployment paused. You can resume later."
    exit 0
fi

# Step 4: Deploy Rails 7
echo ""
echo -e "${BLUE}Step 4: Deploy Rails 7${NC}"
echo "======================"
echo -e "${RED}This will cause application downtime!${NC}"
echo "The deployment process will:"
echo "- Enable maintenance mode"
echo "- Stop all services"
echo "- Deploy new code"
echo "- Run migrations"
echo "- Restart services"
echo ""
read -p "Begin deployment? (yes/no): " RUN_STEP
if [ "$RUN_STEP" = "yes" ]; then
    # Start monitoring in background
    echo "Starting deployment monitor in new terminal..."
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "$SCRIPT_DIR/07_monitor_deployment.sh; read"
    elif command -v xterm &> /dev/null; then
        xterm -e "$SCRIPT_DIR/07_monitor_deployment.sh" &
    else
        echo "Please run monitoring script manually in another terminal:"
        echo "  $SCRIPT_DIR/07_monitor_deployment.sh"
    fi
    
    sleep 3
    
    if ! run_script "04_deploy_rails7.sh"; then
        echo -e "${RED}Deployment failed!${NC}"
        echo ""
        echo "Run the rollback script immediately:"
        echo "  $SCRIPT_DIR/06_rollback.sh"
        exit 1
    fi
fi

# Step 5: Post-deployment verification
echo ""
echo -e "${BLUE}Step 5: Post-deployment Verification${NC}"
echo "===================================="
echo "This will run comprehensive tests on the deployed application."
read -p "Run verification tests? (yes/no): " RUN_STEP
if [ "$RUN_STEP" = "yes" ]; then
    if ! run_script "05_post_deployment_verify.sh"; then
        echo -e "${YELLOW}Some verification tests failed!${NC}"
        echo "Please investigate and fix any issues."
        echo ""
        echo "If the issues are critical, consider rolling back:"
        echo "  $SCRIPT_DIR/06_rollback.sh"
    fi
fi

# Final summary
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Deployment Process Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Summary:"
echo "- Deployment log: $LOG_FILE"
echo "- Monitor script: $SCRIPT_DIR/07_monitor_deployment.sh"
echo "- Rollback script: $SCRIPT_DIR/06_rollback.sh"
echo ""
echo "Post-deployment tasks:"
echo "1. Monitor application performance closely"
echo "2. Check error tracking (Sentry/Airbrake)"
echo "3. Test all critical user workflows"
echo "4. Monitor server resources"
echo "5. Be ready to rollback if issues arise"
echo ""
echo "Useful commands:"
echo "- View logs: tail -f /var/www/memverse/log/production.log"
echo "- Check services: systemctl status memverse-*"
echo "- Monitor resources: $SCRIPT_DIR/07_monitor_deployment.sh"
echo ""

log "Deployment process completed"

# Keep monitoring running
echo -e "${BLUE}The monitoring script should still be running.${NC}"
echo "Press Ctrl+C in the monitoring window to stop it."
echo ""
echo "Good luck with your Rails 7 deployment!"