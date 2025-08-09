#!/bin/bash
# Pre-deployment verification script for Memverse Rails 7 upgrade
# This script checks if the production server meets all requirements

set -e

echo "=========================================="
echo "Memverse Pre-Deployment Verification"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check version requirements
version_ge() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Check if running as appropriate user
echo "1. Checking user permissions..."
if [ "$EUID" -eq 0 ]; then 
   echo -e "${YELLOW}Warning: Running as root. Consider running as the application user.${NC}"
fi
echo "Current user: $(whoami)"
echo ""

# Check OS information
echo "2. Checking Operating System..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME $VERSION"
    echo "OS ID: $ID"
    echo "OS Version ID: $VERSION_ID"
else
    echo -e "${RED}Cannot determine OS version${NC}"
fi
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo ""

# Check system resources
echo "3. Checking System Resources..."
echo "RAM: $(free -h | grep Mem | awk '{print $2}') total, $(free -h | grep Mem | awk '{print $7}') available"
echo "CPU Cores: $(nproc)"
echo "Disk Space:"
df -h | grep -E '^/dev/' | grep -v tmpfs
echo ""

# Check MySQL version and compatibility
echo "4. Checking MySQL Version..."
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version | awk '{print $5}' | awk -F',' '{print $1}')
    echo "MySQL version: $MYSQL_VERSION"
    
    # Extract major.minor version
    MYSQL_MAJOR_MINOR=$(echo $MYSQL_VERSION | cut -d'.' -f1,2)
    
    # Check if MySQL 5.7+ or MariaDB 10.2+
    if [[ $MYSQL_VERSION == *"MariaDB"* ]]; then
        if version_ge "$MYSQL_MAJOR_MINOR" "10.2"; then
            echo -e "${GREEN}MariaDB version is compatible with Rails 7${NC}"
        else
            echo -e "${RED}ERROR: MariaDB version $MYSQL_VERSION is too old. Rails 7 requires MariaDB 10.2+${NC}"
            exit 1
        fi
    else
        if version_ge "$MYSQL_MAJOR_MINOR" "5.7"; then
            echo -e "${GREEN}MySQL version is compatible with Rails 7${NC}"
        else
            echo -e "${RED}ERROR: MySQL version $MYSQL_VERSION is too old. Rails 7 requires MySQL 5.7+${NC}"
            exit 1
        fi
    fi
    
    # Check if we can connect to MySQL
    echo -n "Testing MySQL connection... "
    if mysql -e "SELECT 1" &> /dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}Cannot connect without credentials. Please ensure MySQL access is configured.${NC}"
    fi
else
    echo -e "${RED}MySQL client not found!${NC}"
    exit 1
fi
echo ""

# Check current Ruby version
echo "5. Checking Ruby Version..."
if command -v ruby &> /dev/null; then
    RUBY_VERSION=$(ruby -v | awk '{print $2}')
    echo "Current Ruby version: $RUBY_VERSION"
    
    if [[ $RUBY_VERSION == 2.7.* ]]; then
        echo -e "${YELLOW}Ruby 2.7.x detected. Will need to upgrade to Ruby 3.2.6${NC}"
    elif [[ $RUBY_VERSION == 3.2.6* ]]; then
        echo -e "${GREEN}Ruby 3.2.6 already installed!${NC}"
    else
        echo -e "${YELLOW}Ruby $RUBY_VERSION detected. Will need to install Ruby 3.2.6${NC}"
    fi
else
    echo -e "${RED}Ruby not found!${NC}"
fi

# Check Ruby version manager
echo ""
echo "6. Checking Ruby Version Manager..."
if command -v rvm &> /dev/null; then
    echo "RVM detected: $(rvm --version | head -1)"
    echo "RVM path: $(which rvm)"
elif command -v rbenv &> /dev/null; then
    echo "rbenv detected: $(rbenv --version)"
    echo "rbenv path: $(which rbenv)"
else
    echo -e "${YELLOW}No Ruby version manager detected. Using system Ruby.${NC}"
fi
echo ""

# Check Redis version
echo "7. Checking Redis Version..."
if command -v redis-server &> /dev/null; then
    REDIS_VERSION=$(redis-server --version | awk '{print $3}' | awk -F'=' '{print $2}')
    echo "Redis version: $REDIS_VERSION"
    
    # Extract major version
    REDIS_MAJOR=$(echo $REDIS_VERSION | cut -d'.' -f1)
    
    if [ "$REDIS_MAJOR" -ge 4 ]; then
        echo -e "${GREEN}Redis version is compatible${NC}"
    else
        echo -e "${YELLOW}Redis $REDIS_VERSION is old. Consider upgrading to Redis 6+ for better performance${NC}"
    fi
else
    echo -e "${RED}Redis not found!${NC}"
fi
echo ""

# Check Node.js version
echo "8. Checking Node.js Version..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "Node.js version: $NODE_VERSION"
    
    # Extract major version
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    
    if [ "$NODE_MAJOR" -ge 16 ]; then
        echo -e "${GREEN}Node.js version is compatible${NC}"
    else
        echo -e "${RED}Node.js $NODE_VERSION is too old. Rails 7 assets require Node.js 16+${NC}"
    fi
else
    echo -e "${RED}Node.js not found! Required for asset compilation${NC}"
fi
echo ""

# Check web server
echo "9. Checking Web Server..."
if command -v nginx &> /dev/null; then
    echo "Nginx detected: $(nginx -v 2>&1)"
elif command -v apache2 &> /dev/null; then
    echo "Apache detected: $(apache2 -v | head -1)"
else
    echo -e "${YELLOW}No web server detected${NC}"
fi
echo ""

# Check process manager
echo "10. Checking Process Manager..."
if command -v systemctl &> /dev/null; then
    echo "systemd detected"
    echo "Checking for Memverse services:"
    systemctl list-units --all | grep -i memverse || echo "No Memverse services found"
elif [ -d /etc/init.d ]; then
    echo "SysV init detected"
else
    echo -e "${YELLOW}Unknown process manager${NC}"
fi
echo ""

# Check build tools
echo "11. Checking Build Tools..."
MISSING_TOOLS=()

for tool in gcc g++ make; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS+=($tool)
    fi
done

if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo -e "${GREEN}All build tools present${NC}"
else
    echo -e "${RED}Missing build tools: ${MISSING_TOOLS[*]}${NC}"
    echo "Install with: sudo apt-get install build-essential"
fi
echo ""

# Check for required libraries
echo "12. Checking Required Libraries..."
MISSING_LIBS=()

# Check for MySQL development libraries
if ! pkg-config --exists mysqlclient 2>/dev/null && ! [ -f /usr/include/mysql/mysql.h ]; then
    MISSING_LIBS+=("libmysqlclient-dev")
fi

# Check for ImageMagick
if ! command -v convert &> /dev/null; then
    MISSING_LIBS+=("imagemagick")
fi

# Check for other common requirements
for lib in libxml2-dev libxslt-dev libssl-dev libreadline-dev zlib1g-dev; do
    if ! dpkg -l | grep -q "^ii  $lib"; then
        MISSING_LIBS+=($lib)
    fi
done

if [ ${#MISSING_LIBS[@]} -eq 0 ]; then
    echo -e "${GREEN}All required libraries present${NC}"
else
    echo -e "${YELLOW}Potentially missing libraries: ${MISSING_LIBS[*]}${NC}"
    echo "Install with: sudo apt-get install ${MISSING_LIBS[*]}"
fi
echo ""

# Check current Rails app
echo "13. Checking Current Rails Application..."
if [ -d "$HOME/memverse" ]; then
    APP_DIR="$HOME/memverse"
elif [ -d "/var/www/memverse" ]; then
    APP_DIR="/var/www/memverse"
elif [ -d "/opt/memverse" ]; then
    APP_DIR="/opt/memverse"
else
    echo -e "${YELLOW}Cannot auto-detect Rails app directory. Please specify.${NC}"
    read -p "Enter Rails app directory: " APP_DIR
fi

if [ -d "$APP_DIR" ]; then
    echo "Rails app directory: $APP_DIR"
    cd "$APP_DIR"
    
    if [ -f "Gemfile.lock" ]; then
        echo "Current Rails version: $(grep -A1 "rails (" Gemfile.lock | tail -1 | awk '{print $1}')"
        echo "Current Ruby version in Gemfile: $(grep "ruby " Gemfile | grep -o '"[^"]*"' | tr -d '"')"
    fi
    
    if [ -f ".ruby-version" ]; then
        echo "Ruby version in .ruby-version: $(cat .ruby-version)"
    fi
else
    echo -e "${RED}Rails app directory not found at $APP_DIR${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Pre-Deployment Check Summary"
echo "=========================================="
echo ""
echo "Critical Issues to Address:"
echo ""

# Summarize critical issues
if [[ $MYSQL_VERSION != *"5.7"* ]] && [[ $MYSQL_VERSION != *"8."* ]] && [[ $MYSQL_VERSION != *"10."* ]]; then
    echo -e "${RED}1. MySQL needs upgrade to 5.7+ or MariaDB 10.2+${NC}"
fi

if [[ $RUBY_VERSION != 3.2.6* ]]; then
    echo -e "${RED}2. Ruby needs upgrade to 3.2.6${NC}"
fi

if [ "$NODE_MAJOR" -lt 16 ] 2>/dev/null; then
    echo -e "${RED}3. Node.js needs upgrade to 16+${NC}"
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${RED}4. Install missing build tools: ${MISSING_TOOLS[*]}${NC}"
fi

echo ""
echo "Run this script on your production server before deployment!"