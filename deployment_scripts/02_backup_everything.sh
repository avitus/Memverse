#!/bin/bash
# Comprehensive backup script for Memverse before Rails 7 deployment
# This script creates backups of database, files, and current code

set -e

# Configuration - MODIFY THESE FOR YOUR ENVIRONMENT
APP_DIR="/var/www/memverse"
BACKUP_DIR="/var/backups/memverse/rails7_upgrade_$(date +%Y%m%d_%H%M%S)"
DB_NAME="memverse_production"
DB_USER="memverse"
DB_PASS=""  # Set this or use ~/.my.cnf
UPLOADS_DIR="$APP_DIR/public/uploads"  # Paperclip uploads location

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Memverse Comprehensive Backup"
echo "Date: $(date)"
echo "=========================================="
echo ""

# Create backup directory
echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/database"
mkdir -p "$BACKUP_DIR/files"
mkdir -p "$BACKUP_DIR/code"
mkdir -p "$BACKUP_DIR/config"
echo ""

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 completed successfully${NC}"
    else
        echo -e "${RED}✗ $1 failed!${NC}"
        exit 1
    fi
}

# 1. Record current state
echo "1. Recording current system state..."
cd "$APP_DIR"

# Save current git info
echo "Recording git information..."
{
    echo "Current branch: $(git branch --show-current)"
    echo "Current commit: $(git rev-parse HEAD)"
    echo "Git status:"
    git status
    echo ""
    echo "Git log (last 10 commits):"
    git log --oneline -10
} > "$BACKUP_DIR/git_state.txt"

# Save gem versions
echo "Recording gem versions..."
bundle list > "$BACKUP_DIR/gem_versions.txt"

# Save system info
echo "Recording system information..."
{
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Ruby: $(ruby -v)"
    echo "Rails: $(bundle exec rails -v)"
    echo "MySQL: $(mysql --version)"
    echo "Redis: $(redis-server --version)"
    echo "Node: $(node --version 2>/dev/null || echo 'Not installed')"
} > "$BACKUP_DIR/system_info.txt"

check_status "System state recording"
echo ""

# 2. Database backup
echo "2. Backing up database..."
echo "Database name: $DB_NAME"

# Get current migration version
CURRENT_MIGRATION=$(cd "$APP_DIR" && bundle exec rails db:version | grep "Current version:" | awk '{print $3}')
echo "Current migration version: $CURRENT_MIGRATION"
echo "$CURRENT_MIGRATION" > "$BACKUP_DIR/database/migration_version.txt"

# Full database dump with procedures and triggers
echo "Creating full database dump..."
if [ -z "$DB_PASS" ]; then
    mysqldump -u "$DB_USER" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --complete-insert \
        --add-drop-database \
        --databases "$DB_NAME" | gzip > "$BACKUP_DIR/database/${DB_NAME}_full.sql.gz"
else
    mysqldump -u "$DB_USER" -p"$DB_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --complete-insert \
        --add-drop-database \
        --databases "$DB_NAME" | gzip > "$BACKUP_DIR/database/${DB_NAME}_full.sql.gz"
fi

check_status "Database backup"

# Get database size
DB_SIZE=$(du -sh "$BACKUP_DIR/database/${DB_NAME}_full.sql.gz" | awk '{print $1}')
echo "Database backup size: $DB_SIZE"
echo ""

# 3. File uploads backup (Paperclip files)
echo "3. Backing up uploaded files..."
if [ -d "$UPLOADS_DIR" ]; then
    echo "Backing up Paperclip uploads from $UPLOADS_DIR..."
    
    # Count files
    FILE_COUNT=$(find "$UPLOADS_DIR" -type f | wc -l)
    echo "Number of files to backup: $FILE_COUNT"
    
    # Create tar archive
    tar -czf "$BACKUP_DIR/files/paperclip_uploads.tar.gz" -C "$(dirname "$UPLOADS_DIR")" "$(basename "$UPLOADS_DIR")"
    check_status "Paperclip uploads backup"
    
    # Also backup ckeditor assets if they exist
    if [ -d "$APP_DIR/public/ckeditor_assets" ]; then
        echo "Backing up CKEditor assets..."
        tar -czf "$BACKUP_DIR/files/ckeditor_assets.tar.gz" -C "$APP_DIR/public" "ckeditor_assets"
        check_status "CKEditor assets backup"
    fi
    
    UPLOADS_SIZE=$(du -sh "$BACKUP_DIR/files/" | awk '{print $1}')
    echo "File uploads backup size: $UPLOADS_SIZE"
else
    echo -e "${YELLOW}Warning: Uploads directory not found at $UPLOADS_DIR${NC}"
fi
echo ""

# 4. Application code backup
echo "4. Backing up application code..."
cd "$APP_DIR"

# Get list of files to backup (excluding common large directories)
echo "Creating code archive..."
tar -czf "$BACKUP_DIR/code/app_code.tar.gz" \
    --exclude='log/*' \
    --exclude='tmp/*' \
    --exclude='vendor/bundle/*' \
    --exclude='node_modules/*' \
    --exclude='public/assets/*' \
    --exclude='public/packs/*' \
    --exclude='.git/*' \
    .

check_status "Code backup"

CODE_SIZE=$(du -sh "$BACKUP_DIR/code/app_code.tar.gz" | awk '{print $1}')
echo "Code backup size: $CODE_SIZE"
echo ""

# 5. Configuration files backup
echo "5. Backing up configuration files..."

# Rails configuration
cp -r "$APP_DIR/config" "$BACKUP_DIR/config/rails_config"

# Web server config (adjust paths as needed)
if [ -f "/etc/nginx/sites-available/memverse" ]; then
    cp "/etc/nginx/sites-available/memverse" "$BACKUP_DIR/config/nginx.conf"
fi

if [ -f "/etc/apache2/sites-available/memverse.conf" ]; then
    cp "/etc/apache2/sites-available/memverse.conf" "$BACKUP_DIR/config/apache.conf"
fi

# Systemd services
if [ -d "/etc/systemd/system" ]; then
    cp /etc/systemd/system/memverse* "$BACKUP_DIR/config/" 2>/dev/null || true
fi

# Cron jobs
crontab -l > "$BACKUP_DIR/config/crontab.txt" 2>/dev/null || echo "No crontab found"

# Environment variables (be careful with secrets)
if [ -f "$APP_DIR/.env" ]; then
    cp "$APP_DIR/.env" "$BACKUP_DIR/config/env_file"
    echo -e "${YELLOW}Warning: .env file backed up - contains secrets${NC}"
fi

check_status "Configuration backup"
echo ""

# 6. Create backup manifest
echo "6. Creating backup manifest..."
cat > "$BACKUP_DIR/manifest.txt" << EOF
Memverse Rails 7 Upgrade Backup Manifest
========================================
Backup Date: $(date)
Backup Location: $BACKUP_DIR

System Information:
- Hostname: $(hostname)
- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
- Current Ruby: $(ruby -v)
- Current Rails: $(cd "$APP_DIR" && bundle exec rails -v)
- MySQL Version: $(mysql --version | awk '{print $5}' | awk -F',' '{print $1}')

Database Backup:
- Database: $DB_NAME
- Migration Version: $CURRENT_MIGRATION
- Backup File: database/${DB_NAME}_full.sql.gz
- Size: $DB_SIZE

File Uploads:
- Paperclip Files: $FILE_COUNT files
- Backup Size: $UPLOADS_SIZE

Code Backup:
- Application Code: code/app_code.tar.gz
- Size: $CODE_SIZE

This backup includes:
✓ Full database dump with procedures and triggers
✓ All Paperclip uploaded files
✓ CKEditor assets (if present)
✓ Complete application code
✓ Configuration files
✓ Current gem versions
✓ Git state information

Restore Instructions:
See restore_from_backup.sh script
EOF

check_status "Manifest creation"
echo ""

# 7. Create restore script
echo "7. Creating restore script..."
cat > "$BACKUP_DIR/restore_from_backup.sh" << 'EOF'
#!/bin/bash
# Restore script for Memverse backup

set -e

BACKUP_DIR="$(dirname "$0")"
APP_DIR="/var/www/memverse"

echo "Memverse Restore Script"
echo "======================"
echo "This will restore from backup at: $BACKUP_DIR"
echo ""
echo "WARNING: This will overwrite current data!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 1
fi

# Stop services
echo "Stopping services..."
sudo systemctl stop memverse-puma || true
sudo systemctl stop memverse-sidekiq || true

# Restore code
echo "Restoring application code..."
cd "$APP_DIR"
tar -xzf "$BACKUP_DIR/code/app_code.tar.gz"

# Restore database
echo "Restoring database..."
DB_NAME=$(grep "Database:" "$BACKUP_DIR/manifest.txt" | awk '{print $2}')
gunzip < "$BACKUP_DIR/database/${DB_NAME}_full.sql.gz" | mysql -u root -p

# Restore uploads
echo "Restoring uploaded files..."
if [ -f "$BACKUP_DIR/files/paperclip_uploads.tar.gz" ]; then
    tar -xzf "$BACKUP_DIR/files/paperclip_uploads.tar.gz" -C "$APP_DIR/public"
fi

if [ -f "$BACKUP_DIR/files/ckeditor_assets.tar.gz" ]; then
    tar -xzf "$BACKUP_DIR/files/ckeditor_assets.tar.gz" -C "$APP_DIR/public"
fi

# Restore configuration
echo "Configuration files are in $BACKUP_DIR/config/"
echo "Please manually review and restore as needed."

echo ""
echo "Restore completed!"
echo "Remember to:"
echo "1. Check configuration files"
echo "2. Run bundle install"
echo "3. Restart services"
EOF

chmod +x "$BACKUP_DIR/restore_from_backup.sh"
check_status "Restore script creation"
echo ""

# 8. Verify backup and create checksums
echo "8. Verifying backup integrity..."
cd "$BACKUP_DIR"

# Create checksums
find . -type f -name "*.tar.gz" -o -name "*.sql.gz" | while read file; do
    sha256sum "$file" >> checksums.sha256
done

# Test archives
echo "Testing archive integrity..."
tar -tzf "code/app_code.tar.gz" > /dev/null
check_status "Code archive verification"

gzip -t "database/${DB_NAME}_full.sql.gz"
check_status "Database backup verification"

echo ""

# Final summary
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | awk '{print $1}')

echo "=========================================="
echo -e "${GREEN}Backup completed successfully!${NC}"
echo "=========================================="
echo "Backup location: $BACKUP_DIR"
echo "Total backup size: $TOTAL_SIZE"
echo ""
echo "Backup includes:"
echo "✓ Database dump (with migration version $CURRENT_MIGRATION)"
echo "✓ All uploaded files"
echo "✓ Application code"
echo "✓ Configuration files"
echo "✓ System state information"
echo "✓ Restore script"
echo ""
echo -e "${YELLOW}IMPORTANT: Store this backup in a safe location!${NC}"
echo -e "${YELLOW}Consider copying to: remote server, S3, or external drive${NC}"
echo ""
echo "To copy to remote server:"
echo "rsync -avz $BACKUP_DIR user@backup-server:/path/to/backups/"
echo ""
echo "Next step: Run 03_install_ruby_326.sh"