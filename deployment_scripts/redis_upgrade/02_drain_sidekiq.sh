#!/bin/bash
# Drain Sidekiq Queues Script
# Ensures all background jobs are processed before Redis upgrade

set -e

echo "=== Draining Sidekiq Queues ==="

# 1. Stop Sidekiq from accepting new jobs
echo "1. Stopping Sidekiq workers (quiet mode)..."
sudo systemctl kill -s USR1 sidekiq || pkill -USR1 -f sidekiq

echo "   Sidekiq is now in quiet mode (not accepting new jobs)"

# 2. Wait for queues to drain
echo ""
echo "2. Waiting for queues to drain..."

while true; do
    QUEUE_SIZE=$(redis-cli -n 0 LLEN "queue:default" 2>/dev/null || echo "0")
    RETRY_SIZE=$(redis-cli -n 0 ZCARD "retry" 2>/dev/null || echo "0")
    SCHEDULED_SIZE=$(redis-cli -n 0 ZCARD "schedule" 2>/dev/null || echo "0")
    
    TOTAL=$((QUEUE_SIZE + RETRY_SIZE + SCHEDULED_SIZE))
    
    echo "   Queues: default=$QUEUE_SIZE, retry=$RETRY_SIZE, scheduled=$SCHEDULED_SIZE (Total: $TOTAL)"
    
    if [ "$TOTAL" -eq "0" ]; then
        echo "   All queues are empty!"
        break
    fi
    
    sleep 5
done

# 3. Stop Sidekiq completely
echo ""
echo "3. Stopping Sidekiq service..."
sudo systemctl stop sidekiq || pkill -TERM -f sidekiq

echo ""
echo "=== Sidekiq successfully drained and stopped ==="