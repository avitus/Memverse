#!/bin/bash

# Comprehensive Quiz Monitoring Script
# This script monitors all aspects of the quiz system

LOG_DIR="quiz_monitoring_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

echo "=== Starting Quiz System Monitoring ==="
echo "Logs will be saved to: $LOG_DIR"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/main.log"
}

# Function to check if a process is running
check_process() {
    if pgrep -f "$1" > /dev/null; then
        log "✓ $2 is running"
        return 0
    else
        log "✗ $2 is NOT running"
        return 1
    fi
}

# Function to monitor a log file
monitor_log() {
    local log_file=$1
    local output_file=$2
    local pattern=$3
    
    log "Starting monitor for $log_file (pattern: $pattern)"
    tail -f "$log_file" | grep -E "$pattern" > "$LOG_DIR/$output_file" 2>&1 &
    echo $! >> "$LOG_DIR/pids.txt"
}

# Function to cleanup background processes
cleanup() {
    log "Cleaning up monitoring processes..."
    if [ -f "$LOG_DIR/pids.txt" ]; then
        while read pid; do
            kill $pid 2>/dev/null
        done < "$LOG_DIR/pids.txt"
    fi
}

# Set up trap to cleanup on exit
trap cleanup EXIT

# Step 1: Check system status
log "=== SYSTEM STATUS CHECK ==="
check_process "rails server" "Rails server"
check_process "sidekiq" "Sidekiq"
check_process "redis-server" "Redis"

# Step 2: Set up log monitoring
log "=== SETTING UP LOG MONITORS ==="
monitor_log "log/development.log" "rails_quiz.log" "quiz|Quiz"
monitor_log "log/sidekiq.log" "sidekiq_quiz.log" "Quiz|quiz"

# Step 3: Update quiz start time
log "=== UPDATING QUIZ START TIME ==="
rails_output=$(bundle exec rails runner "
  quiz = Quiz.find(2)
  quiz.update!(start_time: 3.minutes.from_now)
  puts \"Quiz #2 will start at: #{quiz.start_time}\"
" 2>&1)
log "Rails output: $rails_output"

# Step 4: Monitor Redis
log "=== STARTING REDIS MONITOR ==="
(while true; do
    echo "=== Redis Check at $(date) ===" >> "$LOG_DIR/redis.log"
    redis-cli EXISTS quiz-2 >> "$LOG_DIR/redis.log" 2>&1
    redis-cli HGETALL quiz-2 >> "$LOG_DIR/redis.log" 2>&1
    redis-cli ZRANGE quiz:2:scores 0 -1 WITHSCORES >> "$LOG_DIR/redis.log" 2>&1
    echo "" >> "$LOG_DIR/redis.log"
    sleep 10
done) &
echo $! >> "$LOG_DIR/pids.txt"

# Step 5: Check quiz page periodically
log "=== STARTING QUIZ PAGE MONITOR ==="
(while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== Page Check at $timestamp ===" >> "$LOG_DIR/page_check.log"
    
    # Check if quiz page loads
    curl -s -o "$LOG_DIR/quiz_page_${timestamp// /_}.html" \
         -w "HTTP Status: %{http_code}\n" \
         http://localhost:3000/live_quiz/2 >> "$LOG_DIR/page_check.log" 2>&1
    
    # Check for key elements
    if [ -f "$LOG_DIR/quiz_page_${timestamp// /_}.html" ]; then
        echo "Question divs: $(grep -c 'id="question-' "$LOG_DIR/quiz_page_${timestamp// /_}.html")" >> "$LOG_DIR/page_check.log"
        echo "Chat stream: $(grep -c 'chat-stream-narrow' "$LOG_DIR/quiz_page_${timestamp// /_}.html")" >> "$LOG_DIR/page_check.log"
        echo "Quiz timer: $(grep -c 'quiz-timer' "$LOG_DIR/quiz_page_${timestamp// /_}.html")" >> "$LOG_DIR/page_check.log"
        echo "Scoreboard: $(grep -c 'live-quiz-scores' "$LOG_DIR/quiz_page_${timestamp// /_}.html")" >> "$LOG_DIR/page_check.log"
    fi
    echo "" >> "$LOG_DIR/page_check.log"
    
    sleep 30
done) &
echo $! >> "$LOG_DIR/pids.txt"

# Step 6: Monitor for specific quiz events
log "=== MONITORING QUIZ LIFECYCLE ==="
(while true; do
    # Check sidekiq log for quiz stages
    if grep -q "Step 1/7 - Announcing quiz" log/sidekiq.log; then
        echo "[$(date)] ✓ Quiz announcement detected" >> "$LOG_DIR/quiz_stages.log"
    fi
    if grep -q "Step 2/7 - Starting chat period" log/sidekiq.log; then
        echo "[$(date)] ✓ Chat period started" >> "$LOG_DIR/quiz_stages.log"
    fi
    if grep -q "Step 4/7 - Running quiz questions" log/sidekiq.log; then
        echo "[$(date)] ✓ Quiz questions started" >> "$LOG_DIR/quiz_stages.log"
    fi
    if grep -q "Quiz #2.*COMPLETED" log/sidekiq.log; then
        echo "[$(date)] ✓ Quiz completed!" >> "$LOG_DIR/quiz_stages.log"
        break
    fi
    sleep 5
done) &

# Step 7: Generate summary report
log "=== MONITORING IN PROGRESS ==="
log "Check the following files for details:"
log "  - $LOG_DIR/main.log (this log)"
log "  - $LOG_DIR/rails_quiz.log (Rails quiz activity)"
log "  - $LOG_DIR/sidekiq_quiz.log (Sidekiq quiz processing)"
log "  - $LOG_DIR/redis.log (Redis data)"
log "  - $LOG_DIR/page_check.log (Quiz page status)"
log "  - $LOG_DIR/quiz_stages.log (Quiz lifecycle events)"

# Wait for user input or timeout
log "Monitoring will continue for 10 minutes or until you press Ctrl+C"
sleep 600

# Generate final report
log "=== GENERATING FINAL REPORT ==="
echo "Quiz System Monitoring Report" > "$LOG_DIR/REPORT.txt"
echo "Generated at: $(date)" >> "$LOG_DIR/REPORT.txt"
echo "" >> "$LOG_DIR/REPORT.txt"
echo "=== Quiz Stages Completed ===" >> "$LOG_DIR/REPORT.txt"
cat "$LOG_DIR/quiz_stages.log" >> "$LOG_DIR/REPORT.txt" 2>/dev/null
echo "" >> "$LOG_DIR/REPORT.txt"
echo "=== Last Redis State ===" >> "$LOG_DIR/REPORT.txt"
tail -20 "$LOG_DIR/redis.log" >> "$LOG_DIR/REPORT.txt" 2>/dev/null

log "Monitoring complete. Report saved to: $LOG_DIR/REPORT.txt"