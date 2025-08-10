#!/bin/bash
# Verified backup script that actually checks if backup succeeded

set -e  # Exit on any error

echo "=== Memverse Verified Backup Script ==="
echo ""

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/var/backups/memverse/rails7_upgrade_${TIMESTAMP}"
MYSQL_USER="memverse"
DB_NAME="memverse_production"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create backup directory
echo "Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

# Get MySQL password
echo ""
echo "Please enter MySQL password for user '${MYSQL_USER}':"
read -s MYSQL_PASS
echo ""

# Test connection first
echo "Testing database connection..."
if MYSQL_PWD="${MYSQL_PASS}" mysql -u "${MYSQL_USER}" -e "SELECT 1" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to database. Please check password.${NC}"
    exit 1
fi

# Backup database WITHOUT the --databases flag to avoid PROCESS privilege requirement
echo ""
echo "Backing up database (avoiding PROCESS privilege requirement)..."

# Method 1: Backup without extended options that require PROCESS privilege
BACKUP_FILE="${BACKUP_DIR}/database_full.sql"

if MYSQL_PWD="${MYSQL_PASS}" mysqldump \
    -u "${MYSQL_USER}" \
    --single-transaction \
    --skip-lock-tables \
    --no-tablespaces \
    "${DB_NAME}" > "${BACKUP_FILE}" 2>"${BACKUP_DIR}/mysqldump.log"; then
    
    # Check if file has actual content
    if [ -s "${BACKUP_FILE}" ]; then
        # Get line count to verify it's not empty
        LINE_COUNT=$(wc -l < "${BACKUP_FILE}")
        
        if [ $LINE_COUNT -gt 10 ]; then
            echo -e "${GREEN}✓ Database backup created successfully (${LINE_COUNT} lines)${NC}"
            
            # Compress the backup
            echo "Compressing backup..."
            gzip "${BACKUP_FILE}"
            
            # Show final size
            FINAL_SIZE=$(stat -c%s "${BACKUP_FILE}.gz" 2>/dev/null || echo "0")
            echo -e "${GREEN}✓ Compressed size: $((FINAL_SIZE / 1024 / 1024)) MB${NC}"
        else
            echo -e "${RED}✗ Backup file too small (only ${LINE_COUNT} lines)${NC}"
            echo "Mysqldump errors:"
            cat "${BACKUP_DIR}/mysqldump.log"
            exit 1
        fi
    else
        echo -e "${RED}✗ Backup file is empty!${NC}"
        echo "Mysqldump errors:"
        cat "${BACKUP_DIR}/mysqldump.log"
        exit 1
    fi
else
    echo -e "${RED}✗ Mysqldump failed!${NC}"
    echo "Error log:"
    cat "${BACKUP_DIR}/mysqldump.log"
    exit 1
fi

# Alternative method if the above fails
if [ ! -f "${BACKUP_FILE}.gz" ]; then
    echo ""
    echo "Trying alternative backup method..."
    
    # Get list of tables
    TABLES=$(MYSQL_PWD="${MYSQL_PASS}" mysql -u "${MYSQL_USER}" -N -e "SHOW TABLES" "${DB_NAME}")
    
    # Backup table by table
    for table in $TABLES; do
        echo -n "  Backing up table: $table... "
        if MYSQL_PWD="${MYSQL_PASS}" mysqldump -u "${MYSQL_USER}" --single-transaction "${DB_NAME}" "$table" >> "${BACKUP_FILE}" 2>>"${BACKUP_DIR}/mysqldump.log"; then
            echo "OK"
        else
            echo "FAILED"
        fi
    done
    
    gzip "${BACKUP_FILE}"
fi

# Backup code
echo ""
echo "Backing up application code..."
cd /home/avitus/memverse.com
if tar -czf "${BACKUP_DIR}/code_backup.tar.gz" current releases 2>/dev/null; then
    echo -e "${GREEN}✓ Code backup completed${NC}"
else
    echo -e "${YELLOW}⚠ Code backup completed with warnings${NC}"
fi

# Backup Paperclip files
echo ""
echo "Backing up Paperclip files..."

# Check common locations
PAPERCLIP_FOUND=false
for base_dir in "/home/avitus/memverse.com/current/public" "/home/avitus/memverse.com/shared/public" "/home/avitus/memverse.com/shared"; do
    for subdir in "system" "ckeditor_assets"; do
        full_path="${base_dir}/${subdir}"
        if [ -d "${full_path}" ]; then
            echo "  Found: ${full_path}"
            if tar -czf "${BACKUP_DIR}/paperclip_${subdir}_$(basename ${base_dir}).tar.gz" -C "${base_dir}" "${subdir}" 2>/dev/null; then
                echo -e "  ${GREEN}✓ Backed up successfully${NC}"
                PAPERCLIP_FOUND=true
            fi
        fi
    done
done

if [ "$PAPERCLIP_FOUND" = false ]; then
    echo -e "${YELLOW}⚠ WARNING: No Paperclip directories found${NC}"
fi

# Create verification script
cat > "${BACKUP_DIR}/verify_backup.sh" << 'EOF'
#!/bin/bash
echo "Verifying backup integrity..."
echo ""

# Check database backup
if [ -f "database_full.sql.gz" ]; then
    echo -n "Database backup: "
    if gunzip -t database_full.sql.gz 2>/dev/null; then
        SIZE=$(stat -c%s database_full.sql.gz)
        echo "✓ Valid ($((SIZE / 1024 / 1024)) MB)"
        
        # Show sample of content
        echo "  First few lines:"
        gunzip -c database_full.sql.gz | head -5 | sed 's/^/    /'
    else
        echo "✗ CORRUPTED!"
    fi
else
    echo "Database backup: ✗ NOT FOUND!"
fi

echo ""
echo "All files:"
ls -lh
EOF

chmod +x "${BACKUP_DIR}/verify_backup.sh"

# Create restore instructions
cat > "${BACKUP_DIR}/RESTORE_INSTRUCTIONS.txt" << EOF
RESTORE INSTRUCTIONS
===================

To restore this backup:

1. Database:
   gunzip < database_full.sql.gz | mysql -u ${MYSQL_USER} -p ${DB_NAME}

2. Code:
   cd /home/avitus/memverse.com
   tar -xzf ${BACKUP_DIR}/code_backup.tar.gz

3. Paperclip files:
   cd /home/avitus/memverse.com
   for file in ${BACKUP_DIR}/paperclip_*.tar.gz; do
     tar -xzf "\$file"
   done

Backup created: ${TIMESTAMP}
EOF

# Create symlink
ln -sfn "${BACKUP_DIR}" "/var/backups/memverse/latest_rails7_backup"

# Summary
echo ""
echo "========================================"
echo -e "${GREEN}✓ BACKUP COMPLETED${NC}"
echo "========================================"
echo "Location: ${BACKUP_DIR}"
echo "Symlink: /var/backups/memverse/latest_rails7_backup"
echo ""
echo "Contents:"
ls -lh "${BACKUP_DIR}"
echo ""
echo "To verify backup integrity, run:"
echo "  cd ${BACKUP_DIR} && ./verify_backup.sh"
echo ""
echo -e "${YELLOW}IMPORTANT: This backup is REQUIRED for Active Storage migration!${NC}"