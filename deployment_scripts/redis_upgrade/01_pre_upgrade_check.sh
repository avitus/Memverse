#!/bin/bash
# Redis Pre-Upgrade Check Script
# Ensures system is ready for Redis upgrade from 3.2.1 to 6.2

set -e

echo "=== Redis Pre-Upgrade Checklist ==="
echo "Current Redis Version: $(redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')"
echo ""

# 1. Check Sidekiq queue status
echo "1. Checking Sidekiq queues..."
QUEUE_SIZE=$(redis-cli -n 0 LLEN "queue:default" 2>/dev/null || echo "0")
echo "   Default queue size: $QUEUE_SIZE"

if [ "$QUEUE_SIZE" -gt "0" ]; then
    echo "   WARNING: Sidekiq has pending jobs. Consider draining queues first."
fi

# 2. Check active quiz/chat sessions
echo ""
echo "2. Checking active sessions..."
QUIZ_KEYS=$(redis-cli KEYS "quiz*" | wc -l)
CHAT_KEYS=$(redis-cli KEYS "chat-*" | wc -l)
echo "   Active quiz sessions: $QUIZ_KEYS"
echo "   Active chat channels: $CHAT_KEYS"

# 3. Check Redis memory usage
echo ""
echo "3. Current Redis memory usage:"
redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human"

# 4. Check Redis persistence
echo ""
echo "4. Redis persistence status:"
redis-cli CONFIG GET "save" | tail -1
redis-cli CONFIG GET "appendonly" | tail -1

# 5. System checks
echo ""
echo "5. System checks:"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   Available memory: $(free -h | grep Mem | awk '{print $7}')"
echo "   Disk space: $(df -h / | tail -1 | awk '{print $4}' ) available"

echo ""
echo "=== Pre-upgrade check complete ==="