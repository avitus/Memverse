#!/bin/bash
# Real-time monitoring script for Memverse Rails 7 deployment
# Run this during and after deployment to monitor system health

# Configuration
APP_DIR="/var/www/memverse"
LOG_DIR="$APP_DIR/log"
MONITOR_INTERVAL=5  # seconds between checks

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Clear screen and show header
clear
echo "=========================================="
echo "Memverse Deployment Monitor"
echo "Press Ctrl+C to exit"
echo "=========================================="
echo ""

# Function to get service status with color
service_status() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}● Running${NC}"
    else
        echo -e "${RED}● Stopped${NC}"
    fi
}

# Function to format numbers
format_number() {
    printf "%'d" $1
}

# Main monitoring loop
while true; do
    # Clear previous output (keep header)
    tput cup 5 0
    tput ed
    
    # Timestamp
    echo -e "${BLUE}Last Update: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
    
    # 1. Service Status
    echo "SERVICE STATUS"
    echo "=============="
    printf "%-20s %s\n" "Web Server:" "$(service_status memverse-puma)"
    printf "%-20s %s\n" "Background Jobs:" "$(service_status memverse-sidekiq)"
    printf "%-20s %s\n" "Nginx:" "$(service_status nginx)"
    printf "%-20s %s\n" "MySQL:" "$(service_status mysql)"
    printf "%-20s %s\n" "Redis:" "$(service_status redis)"
    echo ""
    
    # 2. System Resources
    echo "SYSTEM RESOURCES"
    echo "================"
    
    # CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    printf "%-20s %.1f%%\n" "CPU Usage:" "$CPU_USAGE"
    
    # Memory Usage
    MEM_INFO=$(free -m | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($MEM_USED/$MEM_TOTAL)*100}")
    printf "%-20s %s MB / %s MB (%.1f%%)\n" "Memory:" "$(format_number $MEM_USED)" "$(format_number $MEM_TOTAL)" "$MEM_PERCENT"
    
    # Disk Usage
    DISK_INFO=$(df -h "$APP_DIR" | tail -1)
    DISK_USED=$(echo $DISK_INFO | awk '{print $3}')
    DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
    DISK_PERCENT=$(echo $DISK_INFO | awk '{print $5}')
    printf "%-20s %s / %s (%s)\n" "Disk Usage:" "$DISK_USED" "$DISK_TOTAL" "$DISK_PERCENT"
    
    # Load Average
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
    printf "%-20s%s\n" "Load Average:" "$LOAD_AVG"
    echo ""
    
    # 3. Application Metrics
    echo "APPLICATION METRICS"
    echo "=================="
    
    # Active connections (example with puma)
    if [ -f "$APP_DIR/tmp/pids/puma.state" ]; then
        PUMA_STATS=$(curl -s http://localhost:9292/stats 2>/dev/null || echo "{}")
        if [ "$PUMA_STATS" != "{}" ]; then
            PUMA_RUNNING=$(echo $PUMA_STATS | jq -r '.running // 0' 2>/dev/null || echo "0")
            PUMA_BACKLOG=$(echo $PUMA_STATS | jq -r '.backlog // 0' 2>/dev/null || echo "0")
            printf "%-20s %s (backlog: %s)\n" "Puma Threads:" "$PUMA_RUNNING" "$PUMA_BACKLOG"
        fi
    fi
    
    # Redis connections
    REDIS_CLIENTS=$(redis-cli info clients 2>/dev/null | grep connected_clients | cut -d: -f2 | tr -d '\r' || echo "0")
    printf "%-20s %s\n" "Redis Clients:" "$REDIS_CLIENTS"
    
    # Sidekiq stats
    if command -v redis-cli &> /dev/null; then
        SIDEKIQ_BUSY=$(redis-cli -n 0 get "memverse:sidekiq:busy" 2>/dev/null || echo "0")
        SIDEKIQ_ENQUEUED=$(redis-cli -n 0 llen "memverse:sidekiq:queue:default" 2>/dev/null || echo "0")
        SIDEKIQ_RETRY=$(redis-cli -n 0 zcard "memverse:sidekiq:retry" 2>/dev/null || echo "0")
        printf "%-20s Busy: %s, Queued: %s, Retry: %s\n" "Sidekiq:" "$SIDEKIQ_BUSY" "$SIDEKIQ_ENQUEUED" "$SIDEKIQ_RETRY"
    fi
    echo ""
    
    # 4. Recent Errors
    echo "RECENT ERRORS (last minute)"
    echo "=========================="
    
    if [ -f "$LOG_DIR/production.log" ]; then
        ERROR_COUNT=$(find "$LOG_DIR/production.log" -mmin -1 -exec grep -i "error\|fatal\|exception" {} \; 2>/dev/null | wc -l)
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "${RED}Found $ERROR_COUNT errors in the last minute:${NC}"
            find "$LOG_DIR/production.log" -mmin -1 -exec grep -i "error\|fatal\|exception" {} \; 2>/dev/null | tail -3
        else
            echo -e "${GREEN}No errors in the last minute${NC}"
        fi
    fi
    echo ""
    
    # 5. Response Time Check
    echo "RESPONSE TIME CHECK"
    echo "=================="
    
    # Check main page response time
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost/ 2>/dev/null || echo "FAIL")
    if [ "$RESPONSE_TIME" != "FAIL" ]; then
        # Convert to milliseconds
        RESPONSE_MS=$(awk "BEGIN {printf \"%.0f\", $RESPONSE_TIME * 1000}")
        if [ "$RESPONSE_MS" -lt 500 ]; then
            echo -e "Homepage: ${GREEN}${RESPONSE_MS}ms${NC}"
        elif [ "$RESPONSE_MS" -lt 1000 ]; then
            echo -e "Homepage: ${YELLOW}${RESPONSE_MS}ms${NC}"
        else
            echo -e "Homepage: ${RED}${RESPONSE_MS}ms${NC}"
        fi
    else
        echo -e "Homepage: ${RED}Not responding${NC}"
    fi
    echo ""
    
    # 6. Database Status
    echo "DATABASE STATUS"
    echo "=============="
    
    # MySQL process list
    MYSQL_PROCESSES=$(mysql -u root -e "SHOW PROCESSLIST" 2>/dev/null | wc -l || echo "0")
    if [ "$MYSQL_PROCESSES" -gt 0 ]; then
        printf "%-20s %s\n" "Active Connections:" "$((MYSQL_PROCESSES - 1))"
        
        # Check for long running queries
        LONG_QUERIES=$(mysql -u root -e "SHOW PROCESSLIST" 2>/dev/null | awk '$6 > 10' | wc -l || echo "0")
        if [ "$LONG_QUERIES" -gt 0 ]; then
            echo -e "${YELLOW}Warning: $LONG_QUERIES long-running queries (>10s)${NC}"
        fi
    else
        echo "Unable to connect to MySQL"
    fi
    
    # Sleep before next update
    sleep $MONITOR_INTERVAL
done