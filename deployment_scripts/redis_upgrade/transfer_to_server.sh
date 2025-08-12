#!/bin/bash
# Transfer Redis upgrade scripts to production server

# Configuration - update these values
REMOTE_USER="avitus"  # or your username
REMOTE_HOST="memverse.com"  # your server hostname/IP
REMOTE_DIR="/home/avitus/redis_upgrade"

echo "=== Transferring Redis upgrade scripts to server ==="
echo "Remote: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"
echo ""

# Create remote directory
echo "Creating remote directory..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DIR}"

# Transfer all scripts
echo "Transferring scripts..."
scp -r *.sh README.md ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

# Make scripts executable on remote
echo "Making scripts executable..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "chmod +x ${REMOTE_DIR}/*.sh"

echo ""
echo "=== Transfer complete! ==="
echo ""
echo "Next steps on the server:"
echo "1. SSH to server: ssh ${REMOTE_USER}@${REMOTE_HOST}"
echo "2. Go to scripts: cd ${REMOTE_DIR}"
echo "3. Review README.md"
echo "4. Run pre-check: ./01_pre_upgrade_check.sh"