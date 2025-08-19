# Sidekiq Background Jobs Documentation

## Overview

Memverse uses Sidekiq for background job processing with Redis as the backend queue store. The system processes various tasks including live quizzes, email reminders, metrics updates, and maintenance operations. Jobs are organized into four priority queues to ensure time-sensitive operations get processed first.

## Configuration

### Main Configuration Files

1. **`config/sidekiq.yml`**
   - Defines queue priorities with weights (higher weight = higher priority)
   - Redis connection settings
   - Concurrency settings (25 workers in production, 5 in development)
   - Dead job retention (6 months)
   - Max retries (25 attempts)

2. **`config/sidekiq_schedule.yml`**
   - Cron-based scheduling for recurring jobs
   - Uses UTC time for all schedules
   - Each job specifies its queue priority

3. **`config/routes.rb`**
   - Mounts Sidekiq Web UI at `/sidekiq` (admin only)
   - Health monitoring endpoints under `/admin/sidekiq_health/*`

## Queue Priority System

Jobs are processed based on queue weights:

| Queue | Weight | Purpose | Example Jobs |
|-------|--------|---------|--------------|
| **critical** | 8 | User-facing, time-sensitive operations | Live quizzes |
| **high** | 4 | Important but not urgent | Email reminders, notifications |
| **default** | 2 | Regular background tasks | Metrics updates |
| **low** | 1 | Maintenance tasks, bulk operations | Tag cloud refresh, subsections |

## All Background Jobs

### 1. KnowledgeQuiz
**File:** `app/workers/knowledge_quiz.rb`
**Queue:** critical
**Schedule:** Tuesday 5pm UTC, Saturday 11pm UTC
**Purpose:** Runs the main Bible knowledge quiz (ID=1)
**Key Features:**
- Real-time quiz with PubNub integration
- 25 multiple-choice questions in production (3 in test)
- Chat channel opens 5 minutes before quiz
- Automatic scoreboard updates
- Winner announcement via Tweet
- Extensive error handling and retry logic
- Redis-based score tracking
- Idempotency checks to prevent duplicate execution

### 2. ScheduledQuiz
**File:** `app/workers/scheduled_quiz.rb`
**Queue:** critical
**Schedule:** Every minute (checks for scheduled quizzes)
**Purpose:** Runs user-created or special quizzes (not the main knowledge quiz)
**Key Features:**
- Handles multiple question types: recitation, reference, MCQ
- Dynamic time allocation based on question length
- Supports custom quiz configurations
- Real-time chat and scoring
- Prevents concurrent execution with locks

### 3. SendReminders
**File:** `app/workers/send_reminders.rb`
**Queue:** high
**Schedule:** Every hour
**Purpose:** Sends progression-based email reminders to users
**Status:** **TEMPORARILY DISABLED** (email provider transition)
**Key Features:**
- Customized emails based on user progression level (1-9)
- Throttled to 50 emails per hour
- Auto-adjusts reminder frequency to avoid being annoying
- Cleans up unactivated users after 2 days
- Progression levels:
  - Level 9: Has memorized one or more verses
  - Level 8: Has completed 3+ sessions
  - Level 7: Has completed 2 sessions
  - Level 6: Has completed 1 session
  - Level 5: Has reviewed at least one verse
  - Level 4: Has added >5 verses
  - Level 3: Has added 1-5 verses
  - Level 2: Confirmed account but no verses
  - Level 1: Unconfirmed email

### 4. ForumReviewNotifier
**File:** `app/workers/forum_review_notifier.rb`
**Queue:** high
**Schedule:** Daily at 8am UTC
**Purpose:** Notifies admins about forum posts needing review
**Key Features:**
- Sends daily digest to admins
- Retry disabled to prevent log flooding

### 5. UpdateMetrics
**File:** `app/workers/update_metrics.rb`
**Queue:** default
**Schedule:** Daily at noon UTC
**Purpose:** Updates daily statistics
**Key Features:**
- Calls `DailyStats.update()` to calculate metrics
- Simple job with retry enabled

### 6. RefreshTagCloud
**File:** `app/workers/refresh_tag_cloud.rb`
**Queue:** low
**Schedule:** March 1st and September 1st at 1:05am UTC
**Purpose:** Rebuilds the verse tag cloud
**Key Features:**
- Deletes all verse tags
- Recreates tags for every verse
- Runs twice yearly
- No retry on failure

### 7. UpdateSubsections
**File:** `app/workers/update_subsections.rb`
**Queue:** low
**Schedule:** March 1st and September 1st at 1:05am UTC
**Purpose:** Calculates passage subsection probabilities
**Key Features:**
- Analyzes passage patterns to identify natural breaks
- Uses statistical analysis of existing passages
- Updates `subsection_end` probability for each verse
- Runs before SubsectionPassages job

### 8. SubsectionPassages
**File:** `app/workers/subsection_passages.rb`
**Queue:** low
**Schedule:** March 2nd and September 2nd at 1:05am UTC
**Purpose:** Creates subsections for active users' passages
**Key Features:**
- Runs after UpdateSubsections completes
- Processes all passages for active users
- Calls `auto_subsection` on each passage

### 9. VerseWebCheck
**File:** `app/workers/verse_web_check.rb`
**Queue:** Not scheduled (triggered on-demand)
**Purpose:** Verifies verse text against web sources
**Trigger:** After a new verse is created (after_commit hook)
**Key Features:**
- Compares database text with web text
- Auto-verifies matching verses
- Logs mismatches for manual review

### 10. UpdateVerseDifficulty (DISABLED)
**File:** `app/workers/update_verse_difficulty.rb`
**Status:** **COMPLETELY COMMENTED OUT** (never tested/verified working)
**Purpose:** Would calculate and normalize verse difficulty scores
**Note:** Code exists but is entirely commented out since Dec 2017

## Job Triggering Mechanisms

### Scheduled Jobs (Cron-based)
Most jobs run on schedules defined in `config/sidekiq_schedule.yml`:
- Knowledge Quiz: Fixed times (Tue/Sat)
- ScheduledQuiz: Every minute (polls for ready quizzes)
- SendReminders: Hourly
- UpdateMetrics: Daily
- ForumReviewNotifier: Daily
- RefreshTagCloud: Bi-annually
- UpdateSubsections: Bi-annually
- SubsectionPassages: Bi-annually

### On-Demand Jobs
- **VerseWebCheck**: Triggered by `Verse` model after_commit hook when a new unverified verse is created

### Manual Triggers
Jobs can be manually triggered via:
- Rails console: `WorkerName.perform_async(args)`
- Sidekiq Web UI: Retry failed jobs
- Admin dashboard: Queue management controls

## Monitoring and Administration

### Web Interfaces

1. **Sidekiq Web UI** (`/sidekiq`)
   - Full Sidekiq dashboard
   - Queue management
   - Job retry/deletion
   - Real-time statistics
   - Admin authentication required

2. **Health Dashboard** (`/admin/sidekiq_health/dashboard`)
   - Custom health monitoring
   - Queue status overview
   - Failed job analysis
   - Performance metrics
   - Auto-refreshes every 30 seconds

### API Endpoints

1. **Health Check** (`/admin/sidekiq_health/health_check`)
   - Returns JSON health status
   - HTTP 200 (healthy) or 503 (unhealthy)
   - Suitable for automated monitoring

2. **Metrics** (`/admin/sidekiq_health/metrics`)
   - Detailed performance metrics
   - Queue depths
   - Job execution times
   - Redis statistics

### Monitoring Features

- **Performance Tracking**: Job execution times, slow job detection (>30s)
- **Error Handling**: Enhanced logging, critical failure alerts
- **Health Checks**: Redis connectivity, queue depths, server heartbeat
- **Queue Management**: Pause/resume queues, retry failures, clear dead jobs

## Redis Data Structure

### Quiz-Related Keys
- `quiz-{id}`: Quiz status and metadata
- `quiz-{id}-participants`: Active participants
- `quiz-{id}-qq-{question_id}`: Question statistics
- `chat-quiz-{id}`: Chat channel status
- `knowledge_quiz_lock`: Prevents concurrent quiz execution
- `scheduled_quiz_lock_{id}`: Per-quiz execution locks

### Temporary Data
- All quiz scores and participant data use TTL
- Chat channels auto-expire
- Lock keys have timeout protection

## Error Handling and Recovery

### Retry Logic
- Default: 25 retries with exponential backoff
- Quiz jobs: No retry (time-sensitive)
- Critical jobs: Custom retry with fallback mechanisms

### Idempotency
- Quiz workers check for concurrent execution
- Lock mechanisms prevent duplicate runs
- Status tracking in Redis

### Failure Recovery
- Failed jobs go to dead set after max retries
- Admin can manually retry from dashboard
- Quiz failures trigger rescheduling
- Email failures are logged but don't block

## Production Considerations

### Performance
- 25 concurrent workers in production
- Redis connection pool size: 30
- Queue weights ensure priority processing
- Monitoring for slow jobs (>30 seconds)

### Deployment
1. Changes to `sidekiq.yml` require Sidekiq restart
2. Schedule changes require sidekiq-cron reload
3. Monitor logs after deployment for errors
4. Check health endpoint after changes

### Scaling
- Adjust concurrency based on server resources
- Monitor Redis memory usage
- Consider separate Sidekiq processes for critical queues
- Use connection pooling for database and Redis

## Troubleshooting

### Common Issues

1. **Quiz not starting**
   - Check Redis connectivity
   - Verify PubNub configuration
   - Look for lock keys in Redis
   - Check Sidekiq process is running

2. **Jobs not processing**
   - Verify queue names match configuration
   - Check Sidekiq is running
   - Look for errors in Sidekiq logs
   - Verify Redis is accessible

3. **High memory usage**
   - Check for missing TTLs on Redis keys
   - Look for stuck jobs in queues
   - Review dead job retention settings

### Log Locations
- Sidekiq logs: `log/sidekiq.log`
- Application logs: `log/production.log`
- Systemd logs: `sudo journalctl -u sidekiq -f`

### Useful Commands
```bash
# Check Sidekiq service status
sudo systemctl status sidekiq

# View real-time Sidekiq logs
sudo journalctl -u sidekiq -f

# Rails console - manual job execution
bundle exec rails console
KnowledgeQuiz.perform_async

# Clear all Redis data (DANGEROUS)
redis-cli FLUSHALL

# Check Redis memory usage
redis-cli INFO memory
```

## Future Improvements

### Potential Enhancements
1. Migrate to Rails 7's native Active Job for better abstraction
2. Implement Sidekiq Pro/Enterprise for enhanced features
3. Add more granular performance metrics
4. Create automated alerts for job failures
5. Implement job result caching
6. Add job dependency management

### Technical Debt
1. Re-enable and test UpdateVerseDifficulty worker
2. Complete email provider migration to re-enable SendReminders
3. Add comprehensive test coverage for all workers
4. Implement circuit breakers for external service calls
5. Add structured logging for better observability