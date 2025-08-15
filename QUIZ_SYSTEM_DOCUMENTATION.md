# Memverse Quiz System Documentation

## Table of Contents
1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [Types of Quizzes](#types-of-quizzes)
4. [Question Types](#question-types)
5. [Creating Quizzes](#creating-quizzes)
6. [Creating Quiz Questions](#creating-quiz-questions)
7. [Running Live Quizzes](#running-live-quizzes)
8. [Quiz Workflow](#quiz-workflow)
9. [Admin Management](#admin-management)
10. [API Endpoints](#api-endpoints)
11. [Technical Architecture](#technical-architecture)

## Overview

The Memverse Quiz System is a real-time Bible knowledge trivia platform that allows users to:
- Participate in scheduled live quizzes
- Create custom quizzes for groups or churches
- Submit and answer quiz questions
- Track scores and compete with other participants
- Test Bible knowledge through multiple question formats

## Database Schema

### Quizzes Table
```sql
create_table "quizzes" do |t|
  t.integer  "user_id"              # Creator of the quiz (required)
  t.string   "name"                 # Name of the quiz
  t.text     "description"          # Description of the quiz
  t.integer  "quiz_questions_count" # Cached count of questions
  t.datetime "start_time"           # When the quiz should start
  t.integer  "quiz_length"          # Total duration in seconds (auto-calculated)
end
```

### Quiz Questions Table
```sql
create_table "quiz_questions" do |t|
  t.integer  "quiz_id"         # Associated quiz (required)
  t.integer  "question_no"     # Question number in sequence
  t.string   "question_type"   # Type: "mcq", "recitation", "reference"
  t.string   "passage"         # Bible reference (e.g., "John 3:16")
  t.text     "mc_question"     # Multiple choice question text
  t.string   "mc_option_a"     # Option A
  t.string   "mc_option_b"     # Option B
  t.string   "mc_option_c"     # Option C
  t.string   "mc_option_d"     # Option D
  t.string   "mc_answer"       # Correct answer (A, B, C, or D)
  t.integer  "times_answered"  # Statistics tracking
  t.decimal  "perc_correct"    # Difficulty tracking (0-100)
  t.string   "mcq_category"    # Category for MCQ
  t.date     "last_asked"      # Last time question was used
  t.integer  "supporting_ref"  # Links to Uberverse table
  t.integer  "submitted_by"    # User who submitted question
  t.string   "approval_status" # "Pending", "Approved", "Rejected"
  t.string   "rejection_code"  # Reason for rejection
end
```

## Types of Quizzes

### 1. Knowledge Quiz (ID = 1)
- **Special Status**: Always has ID = 1 in the system
- **Schedule**: Runs automatically on Wednesdays and Saturdays
- **Duration**: 20 minutes
- **Questions**: 25 questions randomly selected
- **Worker**: Managed by `KnowledgeQuiz` Sidekiq worker
- **Features**:
  - Automatic scheduling via cron
  - Open to all users
  - Questions pulled from approved question pool
  - Difficulty balancing (easy/medium/hard)

### 2. Custom/Scheduled Quizzes (ID > 1)
- **Created By**: Any user with quiz creation permissions
- **Schedule**: Set specific start time
- **Duration**: Calculated based on questions (auto-updated)
- **Questions**: Custom questions added by creator
- **Worker**: Managed by `ScheduledQuiz` Sidekiq worker
- **Features**:
  - Group-specific or church-specific
  - Custom question sets
  - Manual scheduling

## Question Types

### 1. Multiple Choice Questions (MCQ)
```ruby
{
  question_type: "mcq",
  mc_question: "Who was the first king of Israel?",
  mc_option_a: "David",
  mc_option_b: "Solomon", 
  mc_option_c: "Saul",
  mc_option_d: "Samuel",
  mc_answer: "C"
}
```
- **Time Allocation**: 30 seconds
- **Validation**: All options required, 1-120 chars each
- **Question Length**: 8-300 characters

### 2. Recitation Questions
```ruby
{
  question_type: "recitation",
  passage: "John 3:16",
  supporting_ref: 123  # Uberverse ID
}
```
- **Time Allocation**: 2.5 seconds per word + 15 seconds thinking time
- **Purpose**: Type out the verse from memory
- **Translations**: Provides verse in NIV, ESV, NAS, NKJ, KJV

### 3. Reference Questions
```ruby
{
  question_type: "reference",
  passage: "Romans 8:28",
  supporting_ref: 456  # Uberverse ID
}
```
- **Time Allocation**: 25 seconds
- **Purpose**: Identify the reference for a given verse
- **Format**: Given the verse text, provide book/chapter/verse

## Creating Quizzes

### Via Web Interface

1. **Navigate to Quiz Creation**
   ```
   URL: /quizzes/new
   Required Permission: :manage, Quiz
   ```

2. **Fill in Quiz Details**
   ```ruby
   params = {
     quiz: {
       name: "Youth Group Bible Quiz",
       description: "Weekly quiz for our youth group",
       start_time: "2025-01-20 19:00:00"
     }
   }
   ```

3. **Quiz is Created with:**
   - Automatic association with current user
   - Initial quiz_length of 0 (updated as questions are added)
   - Empty question set

### Via Rails Console
```ruby
# Create a new quiz
quiz = Quiz.create!(
  user: User.find_by(email: "quizmaster@example.com"),
  name: "Easter Special Quiz",
  description: "Special quiz focusing on the resurrection story",
  start_time: 2.days.from_now
)
```

## Creating Quiz Questions

### Via Web Interface

1. **Navigate to Question Creation**
   ```
   URL: /quiz_questions/new?quiz=QUIZ_ID
   Required: User must be logged in
   ```

2. **Submit a Multiple Choice Question**
   ```ruby
   params = {
     quiz_question: {
       quiz_id: 5,
       question_type: "mcq",
       mc_question: "What was the name of Moses' brother?",
       mc_option_a: "Aaron",
       mc_option_b: "Abraham",
       mc_option_c: "Adam",
       mc_option_d: "Andrew",
       mc_answer: "A",
       mcq_category: "Old Testament"
     }
   }
   ```

3. **Submit a Recitation Question**
   ```ruby
   params = {
     quiz_question: {
       quiz_id: 5,
       question_type: "recitation",
       passage: "Psalm 23:1-2",
       supporting_ref: Uberverse.find_by(book: "Psalms", chapter: 23, versenum: 1).id
     }
   }
   ```

### Via Rails Console
```ruby
# Add MCQ to quiz
QuizQuestion.create!(
  quiz: quiz,
  question_no: 1,
  question_type: "mcq",
  mc_question: "How many days was Jesus in the tomb?",
  mc_option_a: "One",
  mc_option_b: "Two",
  mc_option_c: "Three",
  mc_option_d: "Four",
  mc_answer: "C",
  submitted_by: current_user.id,
  approval_status: "Approved"
)

# Add reference question
QuizQuestion.create!(
  quiz: quiz,
  question_no: 2,
  question_type: "reference",
  passage: "Matthew 28:6",
  supporting_ref: Uberverse.find_by(book: "Matthew", chapter: 28, versenum: 6).id,
  submitted_by: current_user.id,
  approval_status: "Approved"
)
```

### Automatic Quiz Length Calculation
When questions are added/updated/removed, the quiz length is automatically recalculated:
- **MCQ**: 30 seconds per question
- **Recitation**: Variable based on verse length
- **Reference**: 25 seconds per question
- **Gap**: 1 second between questions

## Running Live Quizzes

### Knowledge Quiz (Automatic)

1. **Scheduled Execution**
   - Runs via Sidekiq cron: Wednesdays and Saturdays
   - Worker: `KnowledgeQuiz.perform_async`
   
2. **Pre-Quiz Phase** (5 minutes before)
   - Chat channel opens
   - Announcement posted to news feed
   - Users can join at `/live_quiz`

3. **Question Selection Algorithm**
   
   **IMPORTANT NOTE**: The Knowledge Quiz uses a **fairness-based selection** algorithm rather than true randomization:
   
   ```ruby
   # Questions are selected using this query:
   QuizQuestion.mcq.approved.order(:last_asked).first
   ```
   
   **Selection Criteria:**
   - **Question Type**: Only Multiple Choice Questions (MCQ)
   - **Approval Status**: Only "Approved" questions
   - **Ordering**: By `last_asked` date (oldest first)
   - **Selection**: Takes the first question (least recently used)
   
   **This means:**
   - Questions rotate fairly - every approved MCQ gets asked before any repeat
   - New approved questions get priority (they have no `last_asked` date)
   - Questions not asked in months appear before recently asked ones
   - No true randomization - predictable rotation ensures all questions get equal exposure
   
   **Available Scopes for Future Enhancement:**
   ```ruby
   # Currently unused but available for selection refinement:
   scope :fresh,   -> { where('last_asked < ?', Date.today - 6.months) }
   scope :easy,    -> { where(perc_correct: 66..100) }
   scope :medium,  -> { where(perc_correct: 34..65) }
   scope :hard,    -> { where(perc_correct: 0..33) }
   ```
   
   **Question Pool Management:**
   - After each question is used, its `last_asked` date is updated to today
   - This pushes it to the end of the queue for next selection
   - Ensures maximum variety between quizzes

4. **Quiz Execution**
   - 25 questions selected sequentially using above algorithm
   - Questions delivered via PubNub real-time messaging
   - 30 seconds allocated per MCQ
   - Scores recorded in Redis
   - Live scoreboard updates after each question

5. **Post-Quiz**
   - Final scoreboard published
   - Question difficulty (`perc_correct`) updated based on performance
   - Statistics tracked: `times_answered` incremented
   - Chat remains open for 10 minutes

### Custom Quiz (Manual)

1. **Create and Schedule Quiz**
   ```ruby
   quiz = Quiz.create!(
     user: current_user,
     name: "Church Quiz Night",
     description: "Monthly Bible quiz",
     start_time: DateTime.parse("2025-01-25 19:00:00")
   )
   ```

2. **Add Questions** (minimum recommended: 10)
   ```ruby
   10.times do |i|
     QuizQuestion.create!(
       quiz: quiz,
       question_no: i + 1,
       question_type: "mcq",
       # ... question details
     )
   end
   ```

3. **Quiz Auto-Starts**
   - `ScheduledQuiz` worker checks every minute
   - Starts quizzes scheduled within next minute
   - Same flow as Knowledge Quiz

### Participating in a Live Quiz

1. **Join the Quiz**
   ```
   URL: /live_quiz?quiz=QUIZ_ID
   Default: /live_quiz (joins Knowledge Quiz, ID=1)
   ```

2. **Requirements**
   - User must be logged in
   - User must have selected a Bible translation
   - Quiz must be active/scheduled

3. **During the Quiz**
   - Questions appear automatically
   - Timer counts down for each question
   - Submit answers before time expires
   - Live scoreboard updates

## Quiz Workflow

### Question Approval Process

1. **User Submits Question**
   - Status: "Pending"
   - Visible at `/quiz_question_approval`

2. **Quizmaster Reviews**
   - Required role: "quizmaster"
   - Can approve or reject with reason code

3. **Approved Questions**
   - Available for Knowledge Quiz pool
   - Can be used in custom quizzes

### Score Recording

```javascript
// Frontend sends score via AJAX
$.post('/record_score', {
  quiz_id: 1,
  usr_id: 123,
  usr_name: "John Doe",
  usr_login: "johndoe",
  question_id: 456,
  question_num: 5,
  score: 10  // Points earned
});
```

Backend processing:
```ruby
# QuizSession service handles score recording
quiz_session = QuizSession.new(quiz_id)
quiz_session.add_participant(user_id, name, login)
quiz_session.update_score(user_id, question_num, score)
quiz_session.update_question_stats(question_num, question_id)
```

## Admin Management

### Quiz Dashboard
```
URL: /admin/quiz_dashboards
Features:
- Monitor live quiz progress
- View participant list
- Manual start/stop controls
- Export results to CSV
- Health monitoring
```

### Permissions

```ruby
# CanCanCan abilities
class Ability
  def initialize(user)
    if user.has_role?("quizmaster")
      can :manage, Quiz
      can :approve, QuizQuestion
      can :access, :quiz_dashboard
    end
    
    if user.present?
      can :create, QuizQuestion
      can :read, Quiz
      can :participate, :live_quiz
    end
  end
end
```

### Admin Actions

1. **Clear Quiz Data**
   ```ruby
   quiz = Quiz.find(1)
   quiz.redis_clear_data  # Clears scores and participants
   ```

2. **Manual Quiz Start**
   ```ruby
   quiz = Quiz.find(5)
   quiz.announce  # Posts announcement
   quiz.status = "starting"
   ```

3. **Lock Quiz for Maintenance**
   ```ruby
   quiz.lock!(duration: 300)  # Lock for 5 minutes
   # ... perform maintenance
   quiz.unlock!
   ```

## API Endpoints

### RESTful Routes
```ruby
# Quizzes
GET    /quizzes           # List all quizzes
GET    /quizzes/new       # New quiz form
POST   /quizzes           # Create quiz
GET    /quizzes/:id       # Show quiz details
GET    /quizzes/:id/edit  # Edit quiz form
PATCH  /quizzes/:id       # Update quiz
DELETE /quizzes/:id       # Delete quiz

# Quiz Questions
GET    /quiz_questions                    # List questions
GET    /quiz_questions/new                # New question form
POST   /quiz_questions                    # Create question
GET    /quiz_questions/:id                # Show question
GET    /quiz_questions/:id/edit           # Edit question
PATCH  /quiz_questions/:id                # Update question
DELETE /quiz_questions/:id                # Delete question
GET    /quiz_question_approval            # Pending approvals
GET    /submit_question                   # Public submission form

# Live Quiz
GET    /live_quiz                         # Join default quiz
GET    /live_quiz/:quiz                   # Join specific quiz
POST   /record_score                      # Submit answer
GET    /live_quiz/till_start/:id.json     # Time until start
```

### API Responses

**Quiz Status**
```json
GET /live_quiz/till_start/1.json

// Before quiz starts:
{ "time": "+0h +5m +30s" }

// During quiz:
{ "status": "in_progress" }

// After quiz:
{ "status": "Finished" }
```

## Technical Architecture

### Components

1. **Models**
   - `Quiz`: Main quiz entity
   - `QuizQuestion`: Individual questions
   - `Uberverse`: Bible verse references
   
2. **Controllers**
   - `QuizzesController`: CRUD operations
   - `QuizQuestionsController`: Question management
   - `LiveQuizController`: Real-time quiz interface

3. **Workers (Sidekiq)**
   - `KnowledgeQuiz`: Runs weekly knowledge quiz
   - `ScheduledQuiz`: Runs custom scheduled quizzes

4. **Services**
   - `QuizSession`: Redis session management
   - `QuizErrorRecovery`: Fallback mechanisms
   - `ChatChannel`: Real-time chat management

5. **Real-time Communication**
   - **PubNub**: Delivers questions and updates
   - **Redis**: Stores live scores and state
   - **Channels**: `quiz-{id}` for each quiz

### Data Flow

```
User joins quiz → LiveQuizController → Renders quiz interface
                                     ↓
Worker starts quiz → Publishes to PubNub → Delivered to all participants
                  ↓
User submits answer → AJAX to /record_score → QuizSession updates Redis
                                            ↓
Worker publishes scoreboard → PubNub → Updates all participants' screens
```

### Redis Data Structure

```ruby
# Participants
"quiz1_user_123" => {
  "name" => "John Doe",
  "login" => "johndoe", 
  "score" => 150,
  "questions_answered" => 10
}

# Question stats
"quiz1_qnum_5" => {
  "total_attempts" => 25,
  "correct_answers" => 18
}

# Quiz status
"quiz-1" => {
  "status" => "in_progress",
  "current_question" => 5,
  "started_at" => "2025-01-15 19:00:00"
}
```

### Modern Features (2025 Update)

1. **Stimulus.js Frontend**
   - Modern JavaScript controller
   - Better error handling
   - Progressive enhancement

2. **Error Recovery**
   - Automatic retry mechanisms
   - Fallback to polling if PubNub fails
   - Database fallback if Redis fails

3. **Feature Flags**
   - `USE_MODERN_QUIZ_INTERFACE` environment variable
   - Gradual rollout capabilities
   - A/B testing support

## Best Practices

### Creating Good Questions

1. **Multiple Choice**
   - Clear, unambiguous question
   - Plausible distractors
   - Avoid "all of the above"
   - Test actual Bible knowledge

2. **Recitation**
   - Choose well-known verses
   - Reasonable length (5-20 words)
   - Consider translation differences

3. **Reference**
   - Use distinctive verses
   - Avoid obscure passages
   - Include context if needed

### Quiz Management

1. **Scheduling**
   - Schedule at least 24 hours in advance
   - Consider time zones
   - Avoid conflicts with Knowledge Quiz

2. **Testing**
   - Test with 3-5 questions first
   - Verify time allocations
   - Check question rendering

3. **Monitoring**
   - Watch participant count
   - Monitor error logs
   - Check Redis memory usage

## Troubleshooting

### Common Issues

1. **Quiz doesn't start**
   - Check Sidekiq is running
   - Verify quiz has questions
   - Check Redis connectivity

2. **Scores not updating**
   - Verify PubNub credentials
   - Check Redis is accessible
   - Review browser console errors

3. **Questions not appearing**
   - Confirm user has translation set
   - Check PubNub subscription
   - Verify quiz status in Redis

### Debugging Commands

```ruby
# Rails console debugging
quiz = Quiz.find(1)
quiz.status                    # Check current status
quiz.redis_participants         # List participants
quiz.quiz_session.get_scoreboard # Get current scores

# Redis CLI debugging
redis-cli
> KEYS quiz*                   # List all quiz keys
> HGETALL quiz-1               # Get quiz status
> HGETALL quiz1_user_123       # Get user score

# Sidekiq monitoring
> Sidekiq::Queue.new("critical").size  # Check queue
> Sidekiq::RetrySet.new.size          # Check retries
> Sidekiq::ScheduledSet.new.size      # Check scheduled
```

## Conclusion

The Memverse Quiz System provides a robust platform for Bible knowledge testing with real-time interaction, automated scheduling, and comprehensive question management. The system supports both automatic weekly quizzes and custom scheduled quizzes for groups, with multiple question formats and difficulty tracking.

For additional help or to report issues, contact the Memverse development team or check the [Live Quiz Revival Plan](./LIVE_QUIZ_REVIVAL_PLAN.md) for recent updates and improvements.