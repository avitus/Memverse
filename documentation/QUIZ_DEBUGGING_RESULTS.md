# Live Quiz Debugging Results

## Summary
The live quiz system has been debugged and the following issues have been identified. The system is partially functional but has a critical issue preventing quiz execution from progressing past the initial setup phase.

## Current Status
- ✅ Sidekiq is running with cron jobs loaded
- ✅ PubNub messaging is functional (confirmed with test message)
- ✅ ScheduledQuiz cron job is running every minute
- ❌ Quiz execution gets stuck at "In progress. Wait for question."
- ❌ No participants can join (count remains 0)

## Issues Identified

### 1. ~~ScheduledQuiz Cron Job Configuration~~ ✅ FIXED
**Problem**: The cron job was using `perform_later` (ActiveJob) instead of `perform_async` (Sidekiq)
**Solution**: Configuration has been corrected in `sidekiq_schedule.yml` with `queue: critical` and `active_job: false`
**Status**: ✅ Resolved - ScheduledQuiz now runs every minute as expected

### 2. Quiz Execution Hangs (CRITICAL ISSUE)
**Problem**: The quiz worker appears to exit early without progressing through the quiz flow
**Symptoms**:
- Quiz starts and sets status to "In progress. Wait for question."
- No further progress (chat doesn't open, questions aren't sent)
- No error messages in logs
- Worker seems to return/exit prematurely

**Likely Cause**: The ScheduledQuiz worker is finding quiz 2 but may be:
1. Failing the time window check (quiz.start_time might be in the past)
2. Getting blocked by the quiz lock mechanism
3. Encountering a silent error in the initialization phase

### 3. High Number of Failed Jobs
- Sidekiq shows 76,000 failed jobs
- Many "Unable to find verse" warnings in logs
- These need to be cleared: `Sidekiq::RetrySet.new.clear`

## Working Components
- ✅ Redis connectivity and quiz session management
- ✅ PubNub connectivity (test message sent successfully)  
- ✅ Quiz creation and basic setup
- ✅ Sidekiq worker infrastructure
- ✅ QuizSession service for Redis operations
- ✅ Cron job scheduling

## Immediate Action Plan

### 1. Add Debug Logging to ScheduledQuiz Worker
Add comprehensive logging to track execution flow:
```ruby
def perform
  Rails.logger.info "===> ScheduledQuiz: Starting perform method"
  
  quiz = find_scheduled_quiz
  Rails.logger.info "===> ScheduledQuiz: Found quiz: #{quiz&.id}"
  return unless quiz
  
  Rails.logger.info "===> ScheduledQuiz: Attempting to acquire lock..."
  # ... rest of the method with similar logging
end
```

### 2. Fix Quiz Time Window Issue
The quiz might have an old start_time. Update it:
```ruby
Quiz.find(2).update!(start_time: 5.minutes.from_now)
```

### 3. Manual Testing Procedure
```bash
# 1. Clear any stuck state
bundle exec rails runner "
  QuizSession.new(2).cleanup_quiz_data
  QuizSession.new(2).unlock_quiz
  Quiz.find(2).update!(start_time: 5.minutes.from_now)
"

# 2. Monitor Sidekiq logs
tail -f log/sidekiq.log | grep -E "Quiz #2|ScheduledQuiz"

# 3. Wait for automatic execution or trigger manually
bundle exec rails runner "ScheduledQuiz.new.perform"

# 4. Check PubNub messages
tail -f log/pubnub.log
```

### 4. Clear Failed Jobs
```ruby
bundle exec rails runner "
  puts 'Failed jobs before: ' + Sidekiq::RetrySet.new.size.to_s
  Sidekiq::RetrySet.new.clear
  puts 'Failed jobs after: ' + Sidekiq::RetrySet.new.size.to_s
"
```

## Root Cause Analysis
The most likely issue is that the ScheduledQuiz worker is:
1. Finding the quiz
2. Checking the time window
3. Determining the quiz start time is not within the next minute
4. Returning early without any error

This would explain why:
- The quiz status shows "In progress" (from manual execution)
- The worker runs every minute but doesn't progress the quiz
- No error messages appear in logs

## Recommended Fix
Update the ScheduledQuiz worker to:
1. Add comprehensive logging at each decision point
2. Handle edge cases where quiz.start_time is in the past
3. Add error handling with explicit error messages
4. Consider adding a "force start" mechanism for debugging