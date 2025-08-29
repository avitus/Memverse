# Quiz Timing Sequence Documentation

This document details the complete time sequence for Memverse quizzes, including all timing-related code locations.

## Overview

The quiz system follows a carefully orchestrated time sequence from scheduling through completion. All timing values are configurable in specific code locations documented below.

## Time Sequence Breakdown

### 1. Pre-Quiz Phase

**T-60 seconds to T-20 seconds**
- Countdown displays in format: "Xm Ys" 
- Updates every 5 seconds
- Location: `app/assets/javascripts/live_quiz.js:213` (`5000` milliseconds)

**T-60 seconds**
- Countdown switches to second-by-second updates
- Location: `app/assets/javascripts/live_quiz.js:204` (`60000` milliseconds threshold)

**T-20 seconds**
- Page auto-refreshes with "Preparing quiz..." message
- Location: `app/assets/javascripts/live_quiz.js:232` (`20000` milliseconds)
- Users are redirected to quiz interface

**T-20 to T-0 seconds**
- Welcome modal displays quiz instructions
- Users can read instructions and click "Let's get started"
- Countdown timer shows time remaining until quiz starts

### 2. Quiz Start Phase

**T-0 seconds**
- Quiz officially begins
- First question is delivered via PubNub
- Question timer starts

### 3. During Quiz Phase

**Question Duration**
- Default: 30 seconds per question
- Location: `app/workers/knowledge_quiz.rb:31` (`QUIZ_QUESTION_DURATION = 30`)
- Location: `app/workers/scheduled_quiz.rb:34` (`QUIZ_QUESTION_DURATION = 30`)

**Question Timer Display**
- Shows countdown for current question
- Turns red in last 5 seconds
- Location: `app/assets/javascripts/memverse_live_quiz.js:117` (`highlightLast5` function)

**Inter-Question Gap**
- 2 second pause between questions
- Location: `app/workers/knowledge_quiz.rb:184` (`sleep(2)`)
- Location: `app/workers/scheduled_quiz.rb:231` (`sleep(2)`)

**Total Quiz Duration**
- Approximately 15-20 minutes depending on number of questions
- Formula: (number_of_questions × (question_duration + 2)) seconds

### 4. Post-Quiz Phase

**Quiz Completion**
- Final scores displayed
- Winners announced
- Chat remains open briefly

**Cleanup**
- Redis data cleared after quiz ends
- Session data expires

## Adjustable Timing Parameters

### 1. Countdown Update Intervals

```javascript
// Initial update frequency (when > 60 seconds remain)
// Location: app/assets/javascripts/live_quiz.js:213
}, 5000); // Update every 5 seconds

// Fast update threshold (switches to 1-second updates)
// Location: app/assets/javascripts/live_quiz.js:204
if (diff > 0 && diff <= 60000 && !self.fastInterval) {

// Fast update interval
// Location: app/assets/javascripts/live_quiz.js:209
}, 1000); // Update every second
```

### 2. Auto-refresh Timing

```javascript
// Auto-refresh threshold (refreshes page before quiz)
// Location: app/assets/javascripts/live_quiz.js:232
if (diff > 0 && diff <= 20000) { // 20 seconds = 20000 milliseconds

// Delay before refresh (to show message)
// Location: app/assets/javascripts/live_quiz.js:236
}, 500); // Small delay to show the message
```

### 3. Quiz Question Timing

```ruby
# Question duration
# Location: app/workers/knowledge_quiz.rb:31
QUIZ_QUESTION_DURATION = 30  # seconds

# Location: app/workers/scheduled_quiz.rb:34
QUIZ_QUESTION_DURATION = 30  # seconds

# Inter-question pause
# Location: app/workers/knowledge_quiz.rb:184
sleep(2)  # 2 second pause

# Location: app/workers/scheduled_quiz.rb:231
sleep(2)  # 2 second pause
```

### 4. Sidekiq Job Thresholds

```ruby
# Quiz job timeout threshold (prevents SLOW JOB warnings)
# Location: config/initializers/sidekiq.rb:117
when 'ScheduledQuiz', 'KnowledgeQuiz'
  600  # 10 minutes for quiz jobs
```

### 5. Quiz Scheduling

```yaml
# Cron schedule for knowledge quiz
# Location: config/sidekiq_schedule.yml
knowledge_quiz:
  cron: "0 9,15 * * 3,6"  # 9:00 and 15:00 UTC on Wednesdays and Saturdays
```

## Timing Considerations

### Network Latency
- PubNub message delivery: ~100-500ms
- Redis operations: ~1-5ms
- Consider adding 1-2 seconds buffer for network delays

### Client-Server Sync
- Use server time for all official timing
- Client countdown is for display only
- Server validates all answer submissions against server time

### Browser Performance
- JavaScript timers may drift on low-powered devices
- Page refresh at T-20 ensures clean state
- Countdown display updates are throttled to prevent excessive rendering

## Testing Different Timings

To test different timing configurations:

1. **Shorter auto-refresh** (e.g., 10 seconds):
   ```javascript
   // app/assets/javascripts/live_quiz.js:232
   if (diff > 0 && diff <= 10000) { // 10 seconds
   ```

2. **Faster question duration** (e.g., 20 seconds):
   ```ruby
   # app/workers/knowledge_quiz.rb:31
   QUIZ_QUESTION_DURATION = 20
   ```

3. **No inter-question pause**:
   ```ruby
   # app/workers/knowledge_quiz.rb:184
   # sleep(2)  # Comment out
   ```

## Monitoring and Debugging

### Check Current Timings
```bash
# View quiz worker logs
tail -f log/sidekiq.log | grep -E "(KnowledgeQuiz|ScheduledQuiz)"

# Check Redis quiz data
redis-cli HGETALL quiz-1

# Monitor PubNub messages
# Enable debug logging in browser console
```

### Common Issues

1. **Timer stuck at specific second**: Check interval clearing logic
2. **Page refreshes too early/late**: Adjust threshold in live_quiz.js
3. **Questions delivered too fast**: Check sleep() calls in workers
4. **SLOW JOB warnings**: Increase threshold in sidekiq.rb

## Future Improvements

- Make question duration configurable per quiz
- Add configuration UI for quiz timing
- Support variable timing per question type
- Add grace period for late joiners