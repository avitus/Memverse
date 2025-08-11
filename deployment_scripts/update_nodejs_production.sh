#!/bin/bash

# Script to update Node.js on production server using NVM
# This upgrades from Node v14 to Node v18 LTS

echo "================================="
echo "Node.js Update Script"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if NVM is installed
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    echo -e "${RED}Error: NVM is not installed${NC}"
    echo "Please install NVM first: https://github.com/nvm-sh/nvm"
    exit 1
fi

# Load NVM
echo -e "${YELLOW}Loading NVM...${NC}"
source ~/.nvm/nvm.sh

# Display current Node version
echo -e "${YELLOW}Current Node.js version:${NC}"
node --version

# Install Node.js 18 LTS (latest LTS as of 2024)
echo -e "${GREEN}Installing Node.js v18 LTS...${NC}"
nvm install 18
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install Node.js v18${NC}"
    exit 1
fi

# Set Node v18 as default
echo -e "${GREEN}Setting Node.js v18 as default...${NC}"
nvm alias default 18
nvm use 18

# Verify installation
echo -e "${GREEN}Verifying installation...${NC}"
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

# Test that Node can handle modern JavaScript
echo -e "${YELLOW}Testing modern JavaScript syntax...${NC}"
node -e "let { test } = { test: 'success' }; console.log('Destructuring test:', test);"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Modern JavaScript syntax works!${NC}"
else
    echo -e "${RED}✗ Modern JavaScript syntax failed${NC}"
    exit 1
fi

# Clean up old Node versions (optional)
echo -e "${YELLOW}Available Node.js versions:${NC}"
nvm list

echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Node.js update completed!${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""
echo "Next steps:"
echo "1. Exit and reconnect to SSH to ensure PATH is updated"
echo "2. Run 'node --version' to verify v18 is active"
echo "3. Retry the Capistrano deployment"
echo ""
echo "To rollback if needed:"
echo "  nvm use 14"
echo "  nvm alias default 14"