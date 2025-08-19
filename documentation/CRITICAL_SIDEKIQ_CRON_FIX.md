# CRITICAL: Sidekiq Cron Jobs Not Running for 3 Years - FIXED

## Issue Discovery
Date: August 15, 2025

**CRITICAL ISSUE**: All Sidekiq cron jobs have been failing to enqueue for approximately 3 years. This means:
- No Bible knowledge quizzes have been running
- No email reminders have been sent (though they're currently disabled anyway)
- No daily metrics updates
- No forum review notifications to admins
- No tag cloud refreshes
- No passage subsection processing

## Root Cause

The `config/sidekiq_schedule.yml` file had `active_job: true` set for all scheduled jobs, but the worker classes are plain `Sidekiq::Worker` classes, NOT ActiveJob classes. This configuration mismatch prevented sidekiq-cron from enqueuing any jobs.

### The Problem Configuration
```yaml
schedule_knowledge_quiz_tuesday:
  cron: "0 17 * * 2"
  class: "KnowledgeQuiz"
  queue: critical
  active_job: true  # ← THIS WAS THE PROBLEM
```

### Why It Failed
- `active_job: true` tells sidekiq-cron to use ActiveJob's `perform_later` method
- But `KnowledgeQuiz` and other workers inherit from `Sidekiq::Worker`, not `ApplicationJob`
- This mismatch caused silent failures - jobs appeared in the Cron tab but were never enqueued

## The Fix

Removed all `active_job: true` lines from `config/sidekiq_schedule.yml`. The corrected configuration:

```yaml
schedule_knowledge_quiz_tuesday:
  cron: "0 17 * * 2"
  class: "KnowledgeQuiz"
  queue: critical
  # No active_job setting - uses plain Sidekiq
```

## Files Changed
- `config/sidekiq_schedule.yml` - Removed all 9 instances of `active_job: true`

## Testing
Created `test_sidekiq_cron.rb` script to verify:
1. All worker classes exist and are valid Sidekiq::Worker classes ✓
2. No active_job configuration conflicts ✓
3. Jobs can be successfully loaded into sidekiq-cron ✓

## Deployment Instructions

### 1. Deploy the Fix
```bash
git add config/sidekiq_schedule.yml
git commit -m "CRITICAL FIX: Re-enable Sidekiq cron jobs after 3 years of failure

- Removed active_job: true from all cron job configurations
- Workers are plain Sidekiq::Worker, not ActiveJob classes
- This mismatch prevented all scheduled jobs from running since ~2022"
```

### 2. Restart Sidekiq in Production
```bash
sudo systemctl restart sidekiq
```

### 3. Verify Jobs Are Running
```bash
# Check Sidekiq logs
sudo journalctl -u sidekiq -f

# In Rails console
bundle exec rails console
Sidekiq::Cron::Job.all.map { |j| [j.name, j.last_enqueue_time] }
```

### 4. Monitor the Cron Tab
- Visit `/sidekiq` in production (as admin)
- Click on "Cron" tab
- Verify "Last Enqueue" times are updating
- Check that "Enqueue Now" button works

## Immediate Actions Needed After Deploy

1. **Knowledge Quiz**: The Tuesday/Saturday quizzes will resume automatically
2. **SendReminders**: Currently disabled - needs email provider fix first
3. **UpdateMetrics**: Will run at noon UTC - check if years of missing data need backfill
4. **ForumReviewNotifier**: Will resume daily at 8am UTC
5. **Tag Cloud & Subsections**: Next run March 1, 2026 - consider manual run

## Monitoring After Fix

Watch for:
- Jobs appearing in queues (check Sidekiq web UI)
- Successful job completions in logs
- Quiz announcements appearing as tweets
- Daily metrics being updated

## Lessons Learned

1. **Silent Failures**: Sidekiq-cron doesn't loudly fail when configuration is wrong
2. **Testing Gap**: No automated tests caught this misconfiguration
3. **Monitoring Gap**: No alerts for "jobs not running"
4. **Documentation**: Worker type (Sidekiq vs ActiveJob) wasn't clearly documented

## Recommended Follow-ups

1. **Add Monitoring**: Create alerts if cron jobs haven't run in expected timeframe
2. **Add Tests**: Add RSpec tests to verify cron job configuration
3. **Backfill Data**: Determine what data needs to be backfilled (metrics, etc.)
4. **User Communication**: Consider notifying users that quizzes are resuming
5. **Documentation**: Update worker documentation to clarify they're plain Sidekiq workers

## Impact Assessment

### What Was Broken (3 years)
- Live Bible quizzes (major feature)
- Daily statistics/metrics
- Email reminders (though separately disabled)
- Forum moderation notifications
- Automated verse difficulty updates

### What Continued Working
- Manual job execution still worked
- On-demand jobs (like VerseWebCheck) still worked
- Redis and Sidekiq infrastructure remained healthy

This fix restores a significant portion of Memverse's automated functionality that has been silently broken since approximately 2022.