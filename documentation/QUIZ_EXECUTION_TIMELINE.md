# Quiz Execution Timeline

This document provides the complete time sequence for Memverse live Bible knowledge quizzes, from initialization through final cleanup. All timing information has been cross-referenced with the actual code implementation.

## Overview

The quiz system follows a carefully orchestrated sequence spanning approximately 35 minutes total:
- **Pre-Quiz Phase**: 5 minutes (chat opens, participants join)
- **Quiz Phase**: ~20 minutes (25 questions with variable timing)
- **Post-Quiz Phase**: 10 minutes (results discussion, cleanup)

## Complete Time Sequence

### Pre-Quiz Phase (T-5:00 to T+0:00)

#### T-5:00 - Quiz Worker Starts
**Sidekiq Cron Job Triggers**:
- **Tuesday**: 17:00 UTC (9:00 AM Pacific)  
- **Saturday**: 23:00 UTC (3:00 PM Pacific)
- Location: `config/sidekiq_schedule.yml`
- Class: `KnowledgeQuiz.perform_async`

**Initialization Process**:
1. Worker acquires Redis lock to prevent duplicate execution
   - Lock timeout: 3600 seconds (1 hour)
   - Execution window: 300 seconds (5 minutes)
   - Location: `app/workers/knowledge_quiz.rb:10-16`

2. Quiz Status Update
   - Status: `"In progress. Initializing..."`
   - Clear old participant scores and question data
   - Location: `app/workers/knowledge_quiz.rb:182-185`

3. Announcements
   - Tweet: "The Bible knowledge quiz is starting. Join now!"
   - iOS push notification sent
   - Location: `app/workers/knowledge_quiz.rb:197-220`

#### T-5:00 to T+0:00 - Pre-Quiz Chat Period
**Chat Channel Opens**:
- Status changes from "Closed" to "Open"
- PubNub message sent to notify connected users
- Channel: `quiz-1` for knowledge quiz
- Location: `app/workers/knowledge_quiz.rb:261-285`

**Chat Duration**:
- **Production**: 300 seconds (5 minutes)
- **Non-production**: 30 seconds (for testing)
- Location: `app/workers/knowledge_quiz.rb:282`

**Participant Activities**:
- Navigate to `/live_quiz`
- Welcome modal displays with instructions
- PubNub connection established
- Presence updates show participant count
- Countdown timer shows time until quiz starts

### Quiz Phase (T+0:00 to ~T+20:00)

#### T+0:00 - Quiz Officially Starts
- Status: `"In progress. Wait for question."`
- Chat remains open during quiz
- First question selection begins
- Location: `app/workers/knowledge_quiz.rb:248`

#### Question Execution Cycle
**Number of Questions**:
- **Production**: 25 questions
- **Non-production**: 5 questions (for testing)
- Location: `app/workers/knowledge_quiz.rb:292`

**Question Selection Process**:
1. Select approved MCQ question ordered by `last_asked`
2. Update `last_asked` timestamp to current UTC date
3. Store question metadata in Redis via QuizSession service
4. Location: `app/workers/knowledge_quiz.rb:302-314`

**Question Broadcast Format**:
```json
{
  "meta": "question",
  "q_id": 123,
  "q_num": 1,
  "q_type": "mcq",
  "mc_question": "Who built the ark?",
  "mc_option_a": "Noah",
  "mc_option_b": "Moses", 
  "mc_option_c": "Abraham",
  "mc_option_d": "David",
  "mc_answer": "a",
  "time_alloc": 30
}
```

**Answer Period Timing**:
- Duration: **Variable per question** (stored in `question.time_allocation`)
- **NOT a fixed 30 seconds** as some documentation suggested
- Default range: 30-60 seconds depending on question difficulty
- Location: `app/workers/knowledge_quiz.rb:327,331`

**Scoring System**:
- Correct answer: 10 points
- Incorrect answer: -2 points  
- No answer: 0 points
- Location: Quiz scoring handled in `/record_score` endpoint

**Inter-Question Gap**:
- **No sleep/pause** between questions in current implementation
- Questions flow immediately after time allocation expires
- Previous documentation mentioned 2-second gaps, but this is not in the current code

#### Scoreboard Updates
- Updated after each question automatically
- Broadcast via PubNub to all participants
- Sorted by score descending
- Location: `app/workers/knowledge_quiz.rb:339-350`

### Post-Quiz Phase (T+20:00 to T+30:00)

#### T+20:00 - Quiz Completion
**Final Status Updates**:
1. Status: `"Finished"`
2. Calculate next quiz time using IceCube scheduling
3. Update question difficulty based on participant performance
4. Location: `app/workers/knowledge_quiz.rb:356-397`

**Difficulty Calculation**:
- Calculate percentage correct for each question
- Update `perc_correct` in database
- Formula: `(total_score / answered_count) * 10`
- Location: `app/workers/knowledge_quiz.rb:369-397`

**Winner Announcement**:
- Tweet: "[Winner Name] won the Bible knowledge quiz"
- Only if there are participants
- Final scoreboard logged
- Location: `app/workers/knowledge_quiz.rb:399-423`

#### T+20:00 to T+30:00 - Post-Quiz Discussion
**Chat Remains Open**:
- **Production**: 600 seconds (10 minutes)  
- **Non-production**: 30 seconds (for testing)
- Participants can discuss answers
- Review questions by clicking dots
- Location: `app/workers/knowledge_quiz.rb:425-443`

#### T+30:00 - Complete Shutdown
**Chat Closure**:
1. Status: `"Closed"`
2. PubNub notification sent
3. No more messages accepted
4. Location: `app/workers/knowledge_quiz.rb:432-442`

**Resource Cleanup**:
1. Release Redis locks
2. Set status to `"Available"`
3. Clean up execution window locks
4. Log completion metrics
5. Location: `app/workers/knowledge_quiz.rb:521-544`

## Frontend Timing Behavior

### Countdown Timer Updates
**Initial Update Frequency**:
- Updates every **5 seconds** when > 60 seconds remain
- Location: `app/assets/javascripts/live_quiz.js:219`

**Fast Update Threshold**:
- Switches to **1-second updates** when ≤ 60 seconds remain
- Location: `app/assets/javascripts/live_quiz.js:210,216`

**Auto-Refresh Behavior**:
- Page refreshes **20 seconds** before quiz start
- Shows "Preparing quiz..." message
- Location: `app/assets/javascripts/live_quiz.js:232-238`

### Question Timer Display
- Shows countdown for current question
- Turns red in last 5 seconds
- Based on `time_alloc` field from question data
- Location: `app/assets/javascripts/memverse_live_quiz.js`

## Technical Configuration

### Redis Keys and TTLs
- Quiz session data: 7200s (2 hours) TTL
- Lock timeout: 3600s (1 hour)
- Key prefix: `quiz_session:1:*`
- Location: `app/services/quiz_session.rb:14,20`

### PubNub Message Types
1. **chat_status**: Opens/closes chat ("Open"/"Closed")
2. **question**: Delivers quiz questions with timing
3. **scoreboard**: Updates participant rankings  
4. **chat**: User messages
5. **presence**: Join/leave events

### Sidekiq Job Configuration
- Queue: `critical` (highest priority)
- Timeout threshold: 600 seconds (10 minutes)
- Retry: `false` (don't retry failed quizzes)
- Location: `app/workers/knowledge_quiz.rb:7`

## Scheduling Details

### Cron Schedule
```yaml
# Tuesday at 17:00 UTC (9:00 AM Pacific)
schedule_knowledge_quiz_tuesday:
  cron: "0 17 * * 2"
  
# Saturday at 23:00 UTC (3:00 PM Pacific)  
schedule_knowledge_quiz_saturday:
  cron: "0 23 * * 6"
```
Location: `config/sidekiq_schedule.yml:10-20`

### Next Quiz Calculation
Uses IceCube gem with weekly recurrence rules:
- Tuesday at 17:00 UTC
- Saturday at 23:00 UTC
- Location: `app/workers/knowledge_quiz.rb:222-230`

## Error Handling & Recovery

### Concurrency Protection
- Redis locks prevent duplicate quiz execution
- Execution window prevents rapid re-runs
- Status checks provide additional safety
- Location: `app/workers/knowledge_quiz.rb:134-167`

### Retry Logic
- Individual operations: 3 retries with exponential backoff (2, 4, 6 seconds)
- PubNub publishing: 3 retries with exponential backoff
- Non-fatal: iOS notifications (quiz continues if they fail)
- Location: `app/workers/knowledge_quiz.rb:449-488`

### Timeout Handling
- Quiz lock: 1 hour (prevents stuck quizzes)
- Sidekiq job: 10 minutes (prevents SLOW JOB warnings)
- Redis operations: Automatic timeout via connection pool

### Late Joiners
- Can join anytime during quiz
- See current question immediately
- Start with 0 points
- Missed questions automatically score 0

### Connection Issues
- PubNub `restore: true` enables reconnection
- Scoreboard updates on reconnect
- Redis data persists through temporary disconnections

## Monitoring & Debugging

### Logging
```bash
# View quiz worker logs
tail -f log/sidekiq.log | grep -E "Knowledge Quiz"

# Check Redis quiz data  
redis-cli HGETALL quiz_session:1:status

# Monitor Sidekiq job status
bundle exec sidekiq -e production -d
```

### Performance Metrics
- Quiz duration typically 25-35 minutes total
- Average question time: 30-60 seconds
- PubNub message delivery: ~100-500ms
- Redis operations: ~1-5ms

## Differences for Custom Quizzes

For quizzes with ID > 1 (custom/private quizzes):
- No automatic cron scheduling (manual start only)
- Custom question count and duration
- Different PubNub channel: `quiz-{id}`
- No iOS notifications
- No Twitter announcements
- Same technical flow once started

## Configuration Adjustments

### Modifying Question Duration
Questions use individual `time_allocation` field - no global constant to change.
To modify timing, update the database:
```sql
UPDATE quiz_questions SET time_allocation = 45 WHERE time_allocation = 30;
```

### Adjusting Chat Periods
Modify constants in `app/workers/knowledge_quiz.rb`:
```ruby
# Pre-quiz chat (line 282)
chat_duration = Rails.env.production? ? 300 : 30

# Post-quiz chat (line 429)  
wait_duration = Rails.env.production? ? 600 : 30
```

### Frontend Timing Changes
Modify JavaScript constants in `app/assets/javascripts/live_quiz.js`:
```javascript
// Auto-refresh threshold (line 232)
if (diff > 0 && diff <= 20000) { // 20 seconds

// Update frequencies (lines 216, 219)
}, 1000); // Fast updates (1 second)
}, 5000); // Slow updates (5 seconds)
```

## Future Improvements

### Suggested Enhancements
- Make pre/post chat durations configurable per quiz
- Add configuration UI for timing parameters  
- Support variable question timing within single quiz
- Add grace period for network latency compensation
- Implement question preview/preparation time
- Add configurable countdown warning intervals

### Monitoring Recommendations
- Track quiz completion rates
- Monitor average question response times
- Alert on excessive Redis operation times
- Log PubNub message delivery failures
- Track participant connection stability