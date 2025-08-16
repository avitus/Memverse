#!/bin/bash

# Script to check database configuration on production server

echo "================================="
echo "Database Configuration Check"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if database.yml exists in shared directory
echo -e "${YELLOW}Checking for database.yml in shared directory...${NC}"
if [ -f "/home/avitus/memverse.com/shared/config/database.yml" ]; then
    echo -e "${GREEN}✓ Found shared/config/database.yml${NC}"
    echo ""
    echo -e "${YELLOW}Production database configuration:${NC}"
    grep -A 10 "^production:" /home/avitus/memverse.com/shared/config/database.yml | grep -v password
else
    echo -e "${RED}✗ No database.yml found in shared/config/${NC}"
    echo "You need to create this file with proper credentials"
fi

echo ""
echo -e "${YELLOW}Checking for Rails credentials...${NC}"
if [ -f "/home/avitus/memverse.com/shared/config/master.key" ]; then
    echo -e "${GREEN}✓ Found master.key${NC}"
else
    echo -e "${RED}✗ No master.key found${NC}"
    echo "You need to copy config/master.key to the server"
fi

echo ""
echo -e "${YELLOW}Testing database connection...${NC}"
echo "Attempting to connect to MySQL..."

# Try to connect without password first (will fail if password required)
mysql -u memverse -e "SELECT 1;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database connection successful (no password)${NC}"
else
    echo -e "${YELLOW}Database requires password - this is expected${NC}"
    echo "Make sure the password is set in Rails credentials or database.yml"
fi

echo ""
echo "================================="
echo "Next Steps:"
echo "================================="
echo "1. Ensure /home/avitus/memverse.com/shared/config/database.yml exists"
echo "2. Verify it has the correct username and password"
echo "3. If using Rails credentials, ensure master.key is present"
echo "4. Example production database.yml:"
echo ""
cat << 'EOF'
production:
  adapter: mysql2
  database: memverse_production
  username: memverse
  password: YOUR_SECURE_PASSWORD_HERE
  host: localhost
  socket: /var/run/mysqld/mysqld.sock
  pool: 30
  reconnect: true
  encoding: utf8
  collation: utf8_general_ci
EOF