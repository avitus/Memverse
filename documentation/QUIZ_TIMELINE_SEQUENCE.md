# Live Quiz Timeline Sequence

## Complete Time Sequence from Start to End

### Pre-Quiz Phase (T-5 minutes)

#### T-5:00 - Quiz Worker Starts
1. **Sidekiq Cron Job Triggers** (Wed 9 AM UTC, Sat 3 PM UTC)
   - `KnowledgeQuiz.perform_async` called
   - Worker acquires Redis lock to prevent duplicate execution

2. **Quiz Initialization**
   - Status: `"In progress. Initializing..."`
   - Clear old scores and participant data
   - Tweet announcement: "The Bible knowledge quiz is starting. Join now!"
   - iOS push notification sent

3. **Chat Channel Opens**
   - Status changes from "Closed" to "Open"
   - PubNub message sent to notify all connected users
   - 5-minute countdown begins

#### T-5:00 to T-0:00 - Pre-Quiz Chat Period
- **Participants Join**
  - Navigate to `/live_quiz`
  - Welcome modal displays with instructions
  - PubNub connection established
  - Presence updates show participant count
  
- **Chat Activity**
  - Participants can chat freely
  - "Quizzers" button shows roster of participants
  - Countdown timer shows time until quiz starts

### Quiz Phase (20 minutes for 25 questions)

#### T+0:00 - Quiz Officially Starts
- Status: `"In progress. Wait for question."`
- Chat remains open
- Question loop begins

#### Question Cycle (Repeats 25 times)
Each question follows this pattern:

1. **Question Selection** (0-2 seconds)
   - Select approved MCQ question ordered by `last_asked`
   - Update `last_asked` timestamp
   - Store question metadata in Redis

2. **Question Broadcast**
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

3. **Answer Period** (30-60 seconds per question)
   - Timer counts down on frontend
   - Participants select answer
   - Answer submitted via `/record_score`
   - Score calculated:
     - Correct: 10 points
     - Incorrect: -2 points
     - No answer: 0 points

4. **Post-Question**
   - Show correct answer highlighted in green
   - Update question dot indicator
   - Sleep for allocated time
   - Update and broadcast scoreboard

#### Scoreboard Updates
After each question:
- Calculate current standings
- Broadcast scoreboard to all participants
- Update participant scores in Redis

### Post-Quiz Phase

#### T+20:00 - Quiz Ends
1. **Final Status Update**
   - Status: `"Finished"`
   - Next quiz time calculated and stored

2. **Difficulty Updates**
   - Calculate percentage correct for each question
   - Update `perc_correct` in database
   - Log statistics

3. **Winner Announcement**
   - Tweet: "[Winner Name] won the Bible knowledge quiz"
   - Final scoreboard displayed

#### T+20:00 to T+30:00 - Post-Quiz Chat
- **10-minute grace period**
- Participants can discuss answers
- Review questions by clicking dots
- Chat remains open

#### T+30:00 - Quiz Completely Ends
1. **Chat Closes**
   - Status: `"Closed"`
   - PubNub notification sent
   - No more messages accepted

2. **Cleanup**
   - Release Redis lock
   - Set status to `"Available"`
   - Log completion metrics

## Timing Summary

| Phase | Duration | Key Activities |
|-------|----------|----------------|
| **Pre-Quiz** | 5 minutes | Chat opens, participants join, instructions shown |
| **Quiz** | ~20 minutes | 25 questions × 30-60 seconds each |
| **Post-Quiz** | 10 minutes | Results discussion, winner announced |
| **Total** | ~35 minutes | From first announcement to chat closure |

## Technical Timeline Details

### Redis Keys and TTLs
- `knowledge_quiz_lock`: 3600s (1 hour) TTL
- `quiz-1` hash: Stores status, metadata
- `quiz-1-participants`: Participant scores
- `quiz-1-question-*`: Question statistics

### PubNub Message Types
1. **chat_status**: Opens/closes chat
2. **question**: Delivers quiz questions
3. **scoreboard**: Updates rankings
4. **chat**: User messages
5. **presence**: Join/leave events

### Frontend State Changes
1. **Welcome Modal** → **Waiting Room** → **Active Quiz** → **Results**
2. Question dots: Gray → Yellow (active) → Green/Red (answered)
3. Timer: Countdown to start → Question timer → "Quiz finished"

## Error Handling & Edge Cases

### Timeouts
- Quiz lock: 1 hour (prevents stuck quizzes)
- Individual operations: 3 retries with exponential backoff

### Concurrent Quiz Prevention
- Redis lock ensures only one instance runs
- Status checks prevent duplicate execution

### Late Joiners
- Can join anytime during quiz
- See current question immediately
- Start with 0 points

### Connection Issues
- PubNub `restore: true` for reconnection
- Missed questions score 0 points
- Scoreboard updates on reconnect

## Custom Quiz Differences

For custom quizzes (ID > 1):
- No automatic scheduling (manual start)
- Custom question count and duration
- Different chat channel (`quiz-{id}`)
- No iOS notifications
- Same flow once started