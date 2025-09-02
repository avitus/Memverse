#!/bin/bash
# Setup script for Sidekiq scheduler and worker services
# This script configures systemd to run 1 scheduler and multiple workers

set -e

echo "=========================================="
echo "Sidekiq Services Setup Script"
echo "=========================================="

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo" 
   exit 1
fi

# Number of worker processes (adjust based on your server capacity)
WORKER_COUNT=${1:-3}

echo "Setting up Sidekiq with:"
echo "  - 1 Scheduler process (handles cron jobs)"
echo "  - $WORKER_COUNT Worker processes (handle job execution)"
echo ""

# Copy service files to systemd directory
echo "1. Copying service files..."
cp sidekiq-scheduler.service /etc/systemd/system/
cp sidekiq-workers@.service /etc/systemd/system/

# Reload systemd daemon
echo "2. Reloading systemd daemon..."
systemctl daemon-reload

# Stop existing sidekiq service if it exists
echo "3. Stopping existing Sidekiq service (if any)..."
systemctl stop sidekiq 2>/dev/null || true
systemctl disable sidekiq 2>/dev/null || true

# Enable and start the scheduler service
echo "4. Setting up Scheduler service..."
systemctl enable sidekiq-scheduler
systemctl start sidekiq-scheduler
echo "   ✓ Scheduler service started"

# Enable and start worker services
echo "5. Setting up Worker services..."
for i in $(seq 1 $WORKER_COUNT); do
    systemctl enable sidekiq-workers@$i
    systemctl start sidekiq-workers@$i
    echo "   ✓ Worker $i started"
done

# Show status
echo ""
echo "6. Service Status:"
echo "----------------------------------------"
systemctl status sidekiq-scheduler --no-pager | head -n 3
echo ""
for i in $(seq 1 $WORKER_COUNT); do
    systemctl status sidekiq-workers@$i --no-pager | head -n 3
    echo ""
done

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Useful commands:"
echo "  - View scheduler logs: journalctl -u sidekiq-scheduler -f"
echo "  - View worker 1 logs:  journalctl -u sidekiq-workers@1 -f"
echo "  - Restart scheduler:   systemctl restart sidekiq-scheduler"
echo "  - Restart all workers: systemctl restart 'sidekiq-workers@*'"
echo "  - Stop all services:   systemctl stop sidekiq-scheduler 'sidekiq-workers@*'"
echo ""
echo "To add more workers:"
echo "  systemctl enable --now sidekiq-workers@4"
echo ""
echo "To check quiz schedules:"
echo "  bundle exec rails c"
echo "  > Sidekiq::Cron::Job.all"
echo ""