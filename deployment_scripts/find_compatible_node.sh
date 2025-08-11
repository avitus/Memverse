#!/bin/bash

# Script to find and install the highest compatible Node.js version
# Tests each version to find what works with the server's glibc

echo "================================="
echo "Node.js Compatibility Finder"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load NVM
source ~/.nvm/nvm.sh

# Check system info
echo -e "${YELLOW}System Information:${NC}"
ldd --version | head -n1
echo ""

# Revert to Node 14 first (we know this works)
echo -e "${YELLOW}Starting from Node v14 (known working)...${NC}"
nvm use 14
nvm alias default 14

# Array of Node versions to try (from newest to oldest)
# v16 is likely the highest that will work with older glibc
versions=("16.20.2" "16.19.0" "16.18.0" "16.17.0" "16.16.0" "16.15.0" "16.14.0" "16.13.0")

echo -e "${YELLOW}Testing Node versions for compatibility...${NC}"
echo ""

working_version=""

for version in "${versions[@]}"; do
    echo -e "${YELLOW}Testing Node v${version}...${NC}"
    
    # Install the version
    nvm install $version > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Try to use it and run a simple command
        nvm use $version > /dev/null 2>&1
        node_test=$(node -e "console.log('ok')" 2>&1)
        
        if [ "$node_test" == "ok" ]; then
            # Test modern JavaScript syntax needed by autoprefixer
            modern_test=$(node -e "let { red, bold, gray } = { red: 'r', bold: 'b', gray: 'g' }; console.log('success');" 2>&1)
            
            if [ "$modern_test" == "success" ]; then
                echo -e "${GREEN}✓ Node v${version} works and supports modern JS!${NC}"
                working_version=$version
                break
            else
                echo -e "${YELLOW}  Node v${version} runs but fails modern JS test${NC}"
            fi
        else
            echo -e "${RED}  Node v${version} has glibc issues${NC}"
            # Clean up this version
            nvm uninstall $version > /dev/null 2>&1
        fi
    else
        echo -e "${RED}  Failed to install Node v${version}${NC}"
    fi
done

echo ""

if [ -n "$working_version" ]; then
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}Found compatible version!${NC}"
    echo -e "${GREEN}=================================${NC}"
    
    # Set the working version as default
    nvm use $working_version
    nvm alias default $working_version
    
    echo -e "${GREEN}Node v${working_version} is now the default${NC}"
    echo "Node version: $(node --version)"
    echo "NPM version: $(npm --version)"
    
    # Final test
    echo ""
    echo -e "${YELLOW}Final verification test:${NC}"
    node -e "
        // Test the exact syntax that was failing in autoprefixer
        let { red, bold, gray, options: colorette } = { 
            red: 'red', 
            bold: 'bold', 
            gray: 'gray', 
            options: { color: true } 
        };
        console.log('✓ Destructuring with rename works');
        
        // Test other modern features
        const arr = [1, 2, 3];
        const [first, ...rest] = arr;
        console.log('✓ Rest parameters work');
        
        const obj = { a: 1, b: 2 };
        const newObj = { ...obj, c: 3 };
        console.log('✓ Spread operator works');
        
        console.log('');
        console.log('All modern JavaScript features working!');
    "
    
    echo ""
    echo -e "${GREEN}Ready for deployment!${NC}"
    echo "The Capistrano deployment should now work."
else
    echo -e "${RED}=================================${NC}"
    echo -e "${RED}No compatible Node version found${NC}"
    echo -e "${RED}=================================${NC}"
    
    echo ""
    echo "Your server's glibc version is too old for Node v15+"
    echo ""
    echo "Options to fix this:"
    echo ""
    echo "1. RECOMMENDED: Upgrade the server OS to Ubuntu 20.04 or newer"
    echo "   - Ubuntu 16.04 reached end of life in 2021"
    echo "   - Newer OS will have updated glibc"
    echo ""
    echo "2. Build Node from source with older glibc"
    echo "   - Complex and time-consuming"
    echo ""
    echo "3. Use Docker for asset compilation"
    echo "   - Isolates Node environment from host OS"
    echo ""
    echo "4. Compile assets locally and commit them"
    echo "   - Quick fix but not ideal for development"
    
    # Keep Node 14 as default
    nvm use 14
    nvm alias default 14
fi