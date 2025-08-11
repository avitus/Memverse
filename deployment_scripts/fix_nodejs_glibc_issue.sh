#!/bin/bash

# Script to install a compatible Node.js version based on glibc availability
# Falls back to Node v16 which has lower glibc requirements

echo "================================="
echo "Node.js Compatibility Fix Script"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load NVM
source ~/.nvm/nvm.sh

# Check OS and glibc version
echo -e "${YELLOW}System Information:${NC}"
echo "OS: $(lsb_release -d 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME)"
echo "glibc version: $(ldd --version | head -n1)"
echo ""

# First, revert to Node 14 to ensure system is working
echo -e "${YELLOW}Reverting to Node v14 temporarily...${NC}"
nvm use 14
nvm alias default 14

# Try Node v16 LTS (has lower glibc requirements than v18)
echo -e "${GREEN}Installing Node.js v16 LTS (lower glibc requirements)...${NC}"
nvm install 16
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install Node.js v16${NC}"
    exit 1
fi

# Test if Node v16 works
echo -e "${YELLOW}Testing Node v16...${NC}"
nvm use 16
node --version
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Node v16 works!${NC}"
    
    # Test modern JavaScript
    node -e "let { test } = { test: 'success' }; console.log('Destructuring test:', test);"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Modern JavaScript syntax works with v16!${NC}"
        
        # Set as default
        echo -e "${GREEN}Setting Node v16 as default...${NC}"
        nvm alias default 16
        
        echo ""
        echo -e "${GREEN}=================================${NC}"
        echo -e "${GREEN}Successfully installed Node v16!${NC}"
        echo -e "${GREEN}=================================${NC}"
        echo "Node version: $(node --version)"
        echo "NPM version: $(npm --version)"
    else
        echo -e "${RED}Modern JavaScript failed with v16${NC}"
        echo -e "${YELLOW}Trying Node v15...${NC}"
        
        # Try Node v15
        nvm install 15
        nvm use 15
        node -e "let { test } = { test: 'success' }; console.log('Test:', test);" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Node v15 works!${NC}"
            nvm alias default 15
        else
            echo -e "${RED}Node v15 also failed, reverting to v14${NC}"
            nvm use 14
            nvm alias default 14
            
            echo ""
            echo -e "${YELLOW}=================================${NC}"
            echo -e "${YELLOW}ALTERNATIVE SOLUTION NEEDED${NC}"
            echo -e "${YELLOW}=================================${NC}"
            echo ""
            echo "Your server's glibc is too old for newer Node versions."
            echo "Options:"
            echo "1. Upgrade the OS (recommended for security)"
            echo "2. Use a Docker container for asset compilation"
            echo "3. Compile assets locally and commit them"
            echo "4. Downgrade autoprefixer-rails to an older version"
            exit 1
        fi
    fi
else
    echo -e "${RED}Node v16 doesn't work on this system${NC}"
    echo -e "${YELLOW}Keeping Node v14 as default${NC}"
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Exit and reconnect to SSH"
echo "2. Retry the deployment"