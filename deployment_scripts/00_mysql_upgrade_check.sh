#!/bin/bash
# MySQL upgrade check and preparation script for Rails 7
# Rails 7 requires MySQL 5.7+ or MariaDB 10.2+

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "MySQL Upgrade Assessment for Rails 7"
echo "=========================================="
echo ""

# Function to check version compatibility
version_ge() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# 1. Check current MySQL version
echo "1. Current MySQL Installation"
echo "============================"

if command -v mysql &> /dev/null; then
    MYSQL_VERSION_FULL=$(mysql --version)
    echo "MySQL command found: $MYSQL_VERSION_FULL"
    
    # Extract version number
    if [[ $MYSQL_VERSION_FULL == *"MariaDB"* ]]; then
        DB_TYPE="MariaDB"
        VERSION=$(echo $MYSQL_VERSION_FULL | grep -oP 'MariaDB\s+\K[0-9]+\.[0-9]+\.[0-9]+')
        MAJOR_MINOR=$(echo $VERSION | cut -d'.' -f1,2)
        REQUIRED_VERSION="10.2"
    else
        DB_TYPE="MySQL"
        VERSION=$(echo $MYSQL_VERSION_FULL | awk '{print $5}' | awk -F',' '{print $1}')
        MAJOR_MINOR=$(echo $VERSION | cut -d'.' -f1,2)
        REQUIRED_VERSION="5.7"
    fi
    
    echo "Database Type: $DB_TYPE"
    echo "Version: $VERSION"
    echo "Major.Minor: $MAJOR_MINOR"
    echo ""
    
    # Check if upgrade is needed
    if version_ge "$MAJOR_MINOR" "$REQUIRED_VERSION"; then
        echo -e "${GREEN}✓ Your $DB_TYPE version ($VERSION) is compatible with Rails 7${NC}"
        UPGRADE_NEEDED="NO"
    else
        echo -e "${RED}✗ Your $DB_TYPE version ($VERSION) is TOO OLD for Rails 7${NC}"
        echo -e "${RED}  Rails 7 requires $DB_TYPE $REQUIRED_VERSION or higher${NC}"
        UPGRADE_NEEDED="YES"
    fi
else
    echo -e "${RED}MySQL client not found!${NC}"
    exit 1
fi

echo ""

# 2. Check data directory and size
echo "2. Database Storage Assessment"
echo "============================="

# Try to find MySQL data directory
if [ -d "/var/lib/mysql" ]; then
    DATA_DIR="/var/lib/mysql"
elif [ -d "/usr/local/mysql/data" ]; then
    DATA_DIR="/usr/local/mysql/data"
else
    echo "Cannot auto-detect MySQL data directory"
    read -p "Enter MySQL data directory path: " DATA_DIR
fi

if [ -d "$DATA_DIR" ]; then
    echo "Data directory: $DATA_DIR"
    echo "Data size: $(du -sh $DATA_DIR 2>/dev/null | awk '{print $1}' || echo 'Unable to determine')"
    echo "Free space: $(df -h $DATA_DIR | tail -1 | awk '{print $4}')"
else
    echo -e "${YELLOW}Cannot access data directory${NC}"
fi

echo ""

# 3. Check for production databases
echo "3. Production Database Check"
echo "=========================="

echo "Attempting to list databases (may require password)..."
echo "Enter MySQL root password when prompted:"

DATABASES=$(mysql -u root -p -e "SHOW DATABASES;" 2>/dev/null | grep -v -E 'Database|information_schema|performance_schema|mysql|sys' || echo "")

if [ -n "$DATABASES" ]; then
    echo "Found databases:"
    echo "$DATABASES"
    
    # Check Memverse database
    if echo "$DATABASES" | grep -q "memverse"; then
        echo ""
        echo -e "${BLUE}Found Memverse databases:${NC}"
        mysql -u root -p -e "SHOW DATABASES LIKE 'memverse%';" 2>/dev/null || true
    fi
else
    echo -e "${YELLOW}Could not list databases (access denied or wrong password)${NC}"
fi

echo ""

# 4. Generate upgrade plan if needed
if [ "$UPGRADE_NEEDED" = "YES" ]; then
    echo "4. MySQL Upgrade Plan"
    echo "===================="
    echo ""
    echo -e "${RED}IMPORTANT: MySQL upgrade is required before deploying Rails 7${NC}"
    echo ""
    
    if [ "$DB_TYPE" = "MySQL" ]; then
        echo "Recommended upgrade path for MySQL:"
        echo "1. Current: MySQL $VERSION"
        
        case "$MAJOR_MINOR" in
            "5.5")
                echo "2. Upgrade to: MySQL 5.6 (intermediate)"
                echo "3. Then upgrade to: MySQL 5.7"
                echo "4. Optionally upgrade to: MySQL 8.0"
                echo ""
                echo -e "${YELLOW}WARNING: Multi-step upgrade required!${NC}"
                ;;
            "5.6")
                echo "2. Upgrade to: MySQL 5.7"
                echo "3. Optionally upgrade to: MySQL 8.0"
                ;;
            *)
                echo "2. Upgrade to: MySQL 5.7 or 8.0"
                ;;
        esac
        
        echo ""
        echo "Upgrade steps for Ubuntu/Debian:"
        echo "--------------------------------"
        cat << 'EOF'
# 1. Backup everything first!
mysqldump --all-databases --single-transaction --quick --lock-tables=false > full_backup.sql

# 2. Add MySQL APT repository
wget https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.22-1_all.deb
# Select MySQL 5.7 or 8.0

# 3. Update and upgrade
sudo apt-get update
sudo apt-get upgrade mysql-server

# 4. Run mysql_upgrade
sudo mysql_upgrade -u root -p

# 5. Restart MySQL
sudo systemctl restart mysql
EOF
        
    elif [ "$DB_TYPE" = "MariaDB" ]; then
        echo "Recommended upgrade path for MariaDB:"
        echo "1. Current: MariaDB $VERSION"
        echo "2. Upgrade to: MariaDB 10.3 or higher"
        echo ""
        
        echo "Upgrade steps for Ubuntu/Debian:"
        echo "--------------------------------"
        cat << 'EOF'
# 1. Backup everything first!
mysqldump --all-databases --single-transaction --quick --lock-tables=false > full_backup.sql

# 2. Add MariaDB repository
sudo apt-get install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64] http://mirror.netcologne.de/mariadb/repo/10.6/ubuntu focal main'

# 3. Update and upgrade
sudo apt-get update
sudo apt-get upgrade mariadb-server

# 4. Run mysql_upgrade
sudo mysql_upgrade -u root -p

# 5. Restart MariaDB
sudo systemctl restart mariadb
EOF
    fi
    
    echo ""
    echo -e "${RED}DO NOT PROCEED with Rails 7 deployment until MySQL is upgraded!${NC}"
    
else
    echo "4. MySQL Compatibility Check"
    echo "=========================="
    echo -e "${GREEN}✓ Your MySQL installation is ready for Rails 7${NC}"
    echo ""
    echo "Pre-deployment checklist:"
    echo "- [ ] Backup database before Rails deployment"
    echo "- [ ] Ensure sufficient disk space (2x current data size)"
    echo "- [ ] Plan for downtime during Rails upgrade"
    echo "- [ ] Test restore procedure"
fi

echo ""
echo "5. MySQL Configuration Check"
echo "=========================="

# Check important MySQL settings
echo "Checking MySQL configuration..."

MYSQL_CONFIG=$(mysql -u root -p -e "SHOW VARIABLES LIKE 'innodb_file_per_table';" 2>/dev/null | grep innodb_file_per_table | awk '{print $2}' || echo "")
if [ "$MYSQL_CONFIG" = "ON" ]; then
    echo -e "${GREEN}✓ innodb_file_per_table is ON (good for performance)${NC}"
else
    echo -e "${YELLOW}⚠ innodb_file_per_table is OFF (consider enabling)${NC}"
fi

# Check character set
CHARSET=$(mysql -u root -p -e "SHOW VARIABLES LIKE 'character_set_database';" 2>/dev/null | grep character_set_database | awk '{print $2}' || echo "")
if [[ "$CHARSET" == "utf8"* ]]; then
    echo -e "${GREEN}✓ Character set is UTF-8 compatible${NC}"
else
    echo -e "${YELLOW}⚠ Character set is $CHARSET (UTF-8 recommended)${NC}"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="

if [ "$UPGRADE_NEEDED" = "YES" ]; then
    echo -e "${RED}ACTION REQUIRED: Upgrade MySQL before deploying Rails 7${NC}"
    echo ""
    echo "1. Backup all databases"
    echo "2. Follow the upgrade steps above"
    echo "3. Test the upgrade in staging first"
    echo "4. Schedule maintenance window"
    echo "5. Have rollback plan ready"
else
    echo -e "${GREEN}MySQL is ready for Rails 7 deployment${NC}"
    echo ""
    echo "Remember to:"
    echo "1. Take a full backup before deployment"
    echo "2. Monitor MySQL during deployment"
    echo "3. Watch for slow queries after upgrade"
fi