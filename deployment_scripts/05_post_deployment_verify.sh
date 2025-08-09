#!/bin/bash
# Post-deployment verification script for Memverse Rails 7 upgrade
# This script thoroughly tests the deployed application

set -e

# Configuration
APP_DIR="/var/www/memverse"
APP_URL="https://www.memverse.com"  # Adjust to your domain
TEST_USER_EMAIL="test@example.com"  # A test account email
API_BASE_URL="$APP_URL/api/v1"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

echo "=========================================="
echo "Memverse Post-Deployment Verification"
echo "Date: $(date)"
echo "=========================================="
echo ""

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function for detailed test with output
run_test_verbose() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Testing: $test_name"
    echo "Command: $test_command"
    if eval "$test_command"; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
    echo ""
}

# 1. System checks
echo "1. System Status Checks"
echo "======================="

run_test "Ruby version 3.2.6" "ruby -v | grep -q '3.2.6'"
run_test "Rails version 7.0" "cd $APP_DIR && bundle exec rails -v | grep -q 'Rails 7'"
run_test "Web service running" "systemctl is-active --quiet memverse-puma"
run_test "Sidekiq service running" "systemctl is-active --quiet memverse-sidekiq"
run_test "Redis connection" "redis-cli ping | grep -q PONG"
run_test "MySQL connection" "cd $APP_DIR && bundle exec rails db:version > /dev/null"

echo ""

# 2. Application endpoints
echo "2. Application Endpoint Tests"
echo "============================="

# Test home page
run_test "Home page loads" "curl -f -s -o /dev/null $APP_URL"
run_test "Home page contains title" "curl -s $APP_URL | grep -q 'Memverse'"

# Test static assets
run_test "CSS assets load" "curl -f -s -o /dev/null $APP_URL/assets/application-*.css"
run_test "JavaScript assets load" "curl -f -s -o /dev/null $APP_URL/assets/application-*.js"
run_test "Images load" "curl -f -s -o /dev/null $APP_URL/assets/logo-*.png"

# Test key pages
run_test "Login page loads" "curl -f -s -o /dev/null $APP_URL/users/sign_in"
run_test "Signup page loads" "curl -f -s -o /dev/null $APP_URL/users/sign_up"
run_test "Verses page loads" "curl -f -s -o /dev/null $APP_URL/verses"
run_test "Leaderboard loads" "curl -f -s -o /dev/null $APP_URL/leaderboard"

echo ""

# 3. API endpoints
echo "3. API Endpoint Tests"
echo "===================="

run_test "API v1 responds" "curl -f -s -o /dev/null $API_BASE_URL/verses"
run_test "API returns JSON" "curl -s -H 'Accept: application/json' $API_BASE_URL/verses | python3 -m json.tool > /dev/null"
run_test "Swagger docs load" "curl -f -s -o /dev/null $APP_URL/api-docs"

echo ""

# 4. Database and migrations
echo "4. Database Verification"
echo "======================="

cd "$APP_DIR"

# Check migration status
echo "Checking migration status..."
PENDING_MIGRATIONS=$(bundle exec rails db:migrate:status | grep "down" | wc -l)
if [ "$PENDING_MIGRATIONS" -eq 0 ]; then
    echo -e "${GREEN}All migrations are up${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}Found $PENDING_MIGRATIONS pending migrations${NC}"
    ((TESTS_FAILED++))
fi

# Check for Active Storage tables
run_test "Active Storage tables exist" "cd $APP_DIR && bundle exec rails runner 'ActiveStorage::Blob.first; puts \"OK\"' 2>/dev/null | grep -q OK"

# Check key models load
run_test "User model loads" "cd $APP_DIR && bundle exec rails runner 'User.first; puts \"OK\"' | grep -q OK"
run_test "Verse model loads" "cd $APP_DIR && bundle exec rails runner 'Verse.first; puts \"OK\"' | grep -q OK"
run_test "Memverse model loads" "cd $APP_DIR && bundle exec rails runner 'Memverse.first; puts \"OK\"' | grep -q OK"

echo ""

# 5. Background jobs
echo "5. Background Job Tests"
echo "======================"

# Check Sidekiq connectivity
run_test "Sidekiq can connect to Redis" "cd $APP_DIR && bundle exec rails runner 'Sidekiq.redis { |c| c.ping }; puts \"OK\"' | grep -q OK"

# Check for failed jobs
echo -n "Checking for failed jobs... "
FAILED_JOBS=$(cd $APP_DIR && bundle exec rails runner "puts Sidekiq::RetrySet.new.size" 2>/dev/null)
if [ "$FAILED_JOBS" = "0" ]; then
    echo -e "${GREEN}No failed jobs${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}$FAILED_JOBS failed jobs in retry queue${NC}"
fi

echo ""

# 6. File uploads (Active Storage)
echo "6. File Upload Tests"
echo "==================="

# Test if uploads directory is accessible
run_test "Uploads directory exists" "test -d $APP_DIR/storage"
run_test "Uploads directory writable" "test -w $APP_DIR/storage"

# Test Active Storage configuration
run_test "Active Storage configured" "cd $APP_DIR && bundle exec rails runner 'Rails.application.config.active_storage; puts \"OK\"' | grep -q OK"

echo ""

# 7. Performance checks
echo "7. Performance Checks"
echo "===================="

# Test response times
echo "Testing response times (should be < 2 seconds)..."
for endpoint in "/" "/verses" "/users/sign_in"; do
    echo -n "  $endpoint: "
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "$APP_URL$endpoint")
    if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
        echo -e "${GREEN}${RESPONSE_TIME}s${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}${RESPONSE_TIME}s (slow!)${NC}"
        ((TESTS_FAILED++))
    fi
done

echo ""

# 8. Error monitoring
echo "8. Error Monitoring"
echo "=================="

# Check application log for errors
echo "Checking application logs for errors..."
RECENT_ERRORS=$(tail -1000 "$APP_DIR/log/production.log" | grep -i "error\|fatal\|exception" | grep -v "Error checking" | wc -l)
if [ "$RECENT_ERRORS" -eq 0 ]; then
    echo -e "${GREEN}No recent errors in logs${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}Found $RECENT_ERRORS error entries in recent logs${NC}"
    echo "Recent errors:"
    tail -1000 "$APP_DIR/log/production.log" | grep -i "error\|fatal\|exception" | tail -5
fi

echo ""

# 9. Security checks
echo "9. Security Checks"
echo "================="

# Check for security headers
run_test "X-Frame-Options header" "curl -s -I $APP_URL | grep -q 'X-Frame-Options'"
run_test "X-Content-Type-Options header" "curl -s -I $APP_URL | grep -q 'X-Content-Type-Options'"
run_test "HTTPS redirect" "curl -s -I http://${APP_URL#https://} | grep -q '301\|302'"

# Check Rails security settings
run_test "Force SSL enabled" "cd $APP_DIR && bundle exec rails runner 'puts Rails.application.config.force_ssl' | grep -q true"
run_test "Secret key base set" "cd $APP_DIR && bundle exec rails runner 'puts Rails.application.credentials.secret_key_base.present?' | grep -q true"

echo ""

# 10. Feature-specific tests
echo "10. Feature-Specific Tests"
echo "========================="

# Test memorization features
run_test "Verse search works" "curl -s '$APP_URL/verses/search?q=John' | grep -q 'results'"
run_test "Bible books load" "curl -s '$APP_URL/verses/books' | grep -q 'Genesis'"

# Test community features
run_test "Groups page loads" "curl -f -s -o /dev/null $APP_URL/groups"
run_test "Leaderboard loads" "curl -f -s -o /dev/null $APP_URL/leaderboard"

# Test API authentication endpoints
run_test "OAuth applications endpoint" "curl -f -s -o /dev/null $APP_URL/oauth/applications"

echo ""

# 11. Generate detailed report
echo "11. Generating Detailed Report"
echo "============================="

REPORT_FILE="$APP_DIR/deployment_report_$(date +%Y%m%d_%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
Memverse Rails 7 Deployment Report
==================================
Generated: $(date)

Deployment Summary:
- Ruby Version: $(ruby -v)
- Rails Version: $(cd $APP_DIR && bundle exec rails -v)
- Current Commit: $(cd $APP_DIR && git rev-parse HEAD)
- Branch: $(cd $APP_DIR && git branch --show-current)

Test Results:
- Tests Passed: $TESTS_PASSED
- Tests Failed: $TESTS_FAILED
- Success Rate: $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))%

System Status:
$(systemctl status memverse-puma --no-pager | head -10)

Recent Errors:
$(tail -100 $APP_DIR/log/production.log | grep -i error | tail -10)

Database Status:
$(cd $APP_DIR && bundle exec rails db:version)

Top Memory Processes:
$(ps aux | sort -rk 4 | head -5)

Disk Usage:
$(df -h | grep -E '^/dev/')
EOF

echo "Detailed report saved to: $REPORT_FILE"
echo ""

# Final summary
echo "=========================================="
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All Tests Passed! ($TESTS_PASSED/$TESTS_PASSED)${NC}"
    echo "=========================================="
    echo "Deployment verification successful!"
else
    echo -e "${RED}Some Tests Failed!${NC}"
    echo "=========================================="
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    echo "Please investigate failed tests before considering the deployment complete."
fi
echo ""
echo "Recommendations:"
echo "1. Monitor application logs: tail -f $APP_DIR/log/production.log"
echo "2. Check Sidekiq dashboard for job processing"
echo "3. Monitor server resources (CPU, memory, disk)"
echo "4. Test critical user workflows manually"
echo "5. Check error tracking service (Sentry/Airbrake)"
echo ""

# Set exit code based on test results
if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
else
    exit 0
fi