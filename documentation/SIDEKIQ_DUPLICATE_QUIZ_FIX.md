# Fix for Duplicate Quiz Announcements

## Problem
The Knowledge Quiz was creating 4 identical announcements instead of 1 when it ran twice weekly. This occurred because:
- Production runs 4 Sidekiq processes for handling load
- Each process independently loaded the cron schedule from `sidekiq_schedule.yml`
- Each process scheduled its own KnowledgeQuiz job
- Result: 4 identical quiz executions = 4 identical "The Bible knowledge quiz is starting" tweets

## Solution: Dedicated Scheduler Process

We've implemented a clean separation between:
1. **One Scheduler Process** - Handles all cron jobs (including KnowledgeQuiz)
2. **Multiple Worker Processes** - Handle job execution only

### Architecture

```
                    ┌─────────────────┐
                    │   Redis Queue   │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
    ┌───────────▼──────────┐   ┌─────────▼─────────┐
    │  Scheduler Process   │   │  Worker Processes │
    │  (Single Instance)   │   │   (3+ Instances)  │
    ├──────────────────────┤   ├───────────────────┤
    │ • Loads cron jobs    │   │ • Process jobs    │
    │ • Enqueues scheduled │   │ • High concurrency│
    │   jobs to Redis      │   │ • No cron loading │
    │ • Low concurrency    │   │                   │
    └──────────────────────┘   └───────────────────┘
```

## Implementation Details

### 1. Configuration Files

#### `/config/sidekiq_scheduler.yml`
- Single instance configuration
- Loads cron jobs
- Low concurrency (5)
- Handles scheduler queue

#### `/config/sidekiq_workers.yml`
- Multiple instance configuration
- Does NOT load cron jobs
- High concurrency (25)
- Handles main job queues

### 2. Sidekiq Initializer Changes

The `/config/initializers/sidekiq.rb` now checks if a process should load cron jobs based on:
- `SIDEKIQ_SCHEDULER=true` environment variable
- OR `:scheduler: true` in config file
- OR `--scheduler` command line flag

### 3. Systemd Services

#### `sidekiq-scheduler.service`
- Runs a single instance
- Sets `SIDEKIQ_SCHEDULER=true`
- Restarts on failure with 30s delay

#### `sidekiq-workers@.service`
- Template for multiple instances
- Sets `SIDEKIQ_SCHEDULER=false`
- More aggressive restart policy

## Deployment Instructions

### For Production Server

1. **Deploy the code changes:**
   ```bash
   git pull origin main
   bundle install
   ```

2. **Copy service files to server:**
   ```bash
   scp deployment_scripts/sidekiq-*.service deploy@production:/tmp/
   scp deployment_scripts/setup_sidekiq_services.sh deploy@production:/tmp/
   ```

3. **SSH to production and run setup:**
   ```bash
   ssh deploy@production
   cd /tmp
   sudo ./setup_sidekiq_services.sh 3  # Creates 3 worker processes
   ```

4. **Verify services are running:**
   ```bash
   sudo systemctl status sidekiq-scheduler
   sudo systemctl status sidekiq-workers@1
   sudo systemctl status sidekiq-workers@2
   sudo systemctl status sidekiq-workers@3
   ```

5. **Check logs to confirm single scheduler:**
   ```bash
   sudo journalctl -u sidekiq-scheduler -n 50
   # Should see: "[SIDEKIQ SCHEDULER] Loaded X scheduled jobs"
   
   sudo journalctl -u sidekiq-workers@1 -n 50
   # Should see: "[SIDEKIQ WORKER] This process will NOT handle cron jobs"
   ```

6. **Verify cron jobs are loaded only once:**
   ```bash
   cd /var/www/memverse/current
   bundle exec rails c
   > Sidekiq::Cron::Job.all.map(&:name)
   # Should show each job only once, including:
   # ["schedule_knowledge_quiz_tuesday", "schedule_knowledge_quiz_saturday"]
   ```

## Monitoring

### Check Quiz Execution

Monitor the next quiz execution to ensure only 2 tweets are created (start + winner):

```bash
# Watch scheduler logs during quiz time
sudo journalctl -u sidekiq-scheduler -f | grep KnowledgeQuiz

# Check tweet creation in Rails console
bundle exec rails c
> Tweet.where("news LIKE ?", "%quiz%").order(created_at: :desc).limit(10)
```

### Expected Log Output

**Scheduler Process:**
```
[SIDEKIQ SCHEDULER] This process will handle cron jobs
[SIDEKIQ SCHEDULER] Loaded 10 scheduled jobs:
[SIDEKIQ SCHEDULER]   - schedule_knowledge_quiz_tuesday: 0 17 * * 2 (KnowledgeQuiz)
[SIDEKIQ SCHEDULER]   - schedule_knowledge_quiz_saturday: 0 23 * * 6 (KnowledgeQuiz)
```

**Worker Processes:**
```
[SIDEKIQ WORKER] This process will NOT handle cron jobs (worker only)
```

## Rollback Plan

If issues occur, rollback to the old single service:

```bash
# Stop new services
sudo systemctl stop sidekiq-scheduler 'sidekiq-workers@*'
sudo systemctl disable sidekiq-scheduler 'sidekiq-workers@*'

# Re-enable old service
sudo systemctl enable sidekiq
sudo systemctl start sidekiq
```

## Benefits

1. **No Duplicate Executions**: Only one process schedules cron jobs
2. **Better Resource Usage**: Scheduler has low concurrency, workers have high
3. **Cleaner Architecture**: Clear separation of concerns
4. **Easy Scaling**: Add more workers without affecting scheduling
5. **Simpler Than Leader Election**: No complex distributed locking needed

## Testing

### Local Testing

```bash
# Terminal 1 - Run scheduler
SIDEKIQ_SCHEDULER=true bundle exec sidekiq -C config/sidekiq_scheduler.yml

# Terminal 2 - Run worker
bundle exec sidekiq -C config/sidekiq_workers.yml

# Terminal 3 - Check loaded jobs
bundle exec rails c
> Sidekiq::Cron::Job.all.count  # Should show jobs
```

### Production Validation

After deployment, wait for the next scheduled quiz (Tuesday 5pm UTC or Saturday 11pm UTC) and verify:
1. Only 2 tweets created (start announcement + winner)
2. Quiz runs successfully
3. No duplicate job executions in logs

## Troubleshooting

### Issue: No cron jobs running
- Check scheduler service: `sudo systemctl status sidekiq-scheduler`
- Verify SIDEKIQ_SCHEDULER env var: `sudo systemctl show sidekiq-scheduler | grep Environment`
- Check logs: `sudo journalctl -u sidekiq-scheduler -n 100`

### Issue: Still seeing duplicates
- Ensure old sidekiq service is stopped: `sudo systemctl status sidekiq`
- Check for rogue processes: `ps aux | grep sidekiq`
- Verify only one scheduler: `sudo systemctl status 'sidekiq-*'`

### Issue: Jobs not being processed
- Check worker services: `sudo systemctl status 'sidekiq-workers@*'`
- Verify Redis connection: `redis-cli ping`
- Check queue depths: `bundle exec rails c` then `Sidekiq::Queue.all.map { |q| [q.name, q.size] }`

## Additional Notes

- The scheduler process can also handle some job processing (it has queues configured)
- Worker count can be adjusted based on load (typically 2-4 workers)
- Each worker process can handle 25 concurrent jobs
- The scheduler only needs 5 concurrent threads since it mainly enqueues jobs