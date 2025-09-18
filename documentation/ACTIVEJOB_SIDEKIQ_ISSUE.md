# ActiveJob Sidekiq Configuration Issue

## Problem Summary
On September 18, 2025, the production website experienced downtime with "This website is under heavy load (queue full)" errors. Investigation revealed that ActiveJob was not configured to use Sidekiq as the queue adapter, causing all background jobs to run synchronously in the web server process.

## Root Cause
The production.rb configuration file was missing the ActiveJob queue adapter setting:

```ruby
# This line was commented out:
# config.active_job.queue_adapter = :resque
```

Without this configuration, Rails defaults to the `:async` adapter, which processes jobs in an in-process thread pool. This causes:
- Jobs to block web requests
- Memory bloat in web server processes
- "Queue full" errors under moderate load
- Poor user experience with slow page loads

## Solution

### 1. Fixed Production Configuration
Added to `config/environments/production.rb`:

```ruby
# Use Sidekiq for Active Job queue backend
config.active_job.queue_adapter = :sidekiq
```

### 2. Deployment Steps

```bash
# Deploy the fix
cap production deploy

# Verify on production server
cd /path/to/memverse/current
bundle exec rails console -e production
> Rails.application.config.active_job.queue_adapter
=> :sidekiq

# Restart web servers to pick up new config
sudo systemctl restart puma # or passenger, unicorn, etc.

# Ensure Sidekiq is running
sudo systemctl status sidekiq-scheduler
sudo systemctl status sidekiq-workers@1
```

### 3. Prevention Measures

#### A. Health Check Rake Task
Created `lib/tasks/sidekiq_health_check.rake` with two tasks:

```bash
# Manual health check
bundle exec rake sidekiq:health_check

# Automated monitoring (add to cron)
bundle exec rake sidekiq:monitor
```

#### B. Monitoring Cron Job
Add to production crontab:

```cron
# Check Sidekiq health every 5 minutes
*/5 * * * * cd /path/to/memverse && bundle exec rake sidekiq:monitor RAILS_ENV=production >> log/sidekiq_monitor.log 2>&1
```

#### C. Deployment Checklist
Add to deployment process:
1. Verify ActiveJob adapter: `Rails.application.config.active_job.queue_adapter`
2. Check Sidekiq processes: `ps aux | grep sidekiq`
3. Monitor queue latency: `Sidekiq::Queue.new.latency`
4. Review logs for "Async(default)" entries (indicates misconfiguration)

## Testing

### Development Testing
```bash
# Start without Sidekiq to test async behavior
rails server

# In another terminal, trigger a background job
rails console
> User.first.send_reminder_email
# Should see job execute immediately in server logs

# Now test with Sidekiq
./bin/dev # or bundle exec sidekiq
# Repeat the test - job should go to Sidekiq
```

### Production Verification
```bash
# SSH to production
bundle exec rails console -e production

# Verify configuration
> Rails.application.config.active_job.queue_adapter
=> :sidekiq

# Test job enqueueing
> TestJob = Class.new(ApplicationJob) { def perform; Rails.logger.info "Test job ran"; end }
> TestJob.perform_later
# Should see job ID, not immediate execution

# Check Sidekiq picked it up
> Sidekiq::Stats.new.processed
# Number should increase
```

## Symptoms to Watch For

### Signs of Misconfiguration:
1. Log entries showing `[ActiveJob] ... from Async(default)`
2. Slow page loads when triggering background jobs
3. High memory usage in web server processes
4. "Queue full" errors in production
5. Background jobs executing immediately instead of asynchronously

### Healthy System Indicators:
1. Log entries showing `[ActiveJob] ... from Sidekiq(default)`
2. Consistent web response times
3. Jobs visible in Sidekiq web UI
4. Low latency in Sidekiq queues

## Additional Notes

- This issue can occur after Rails upgrades if configuration isn't properly migrated
- The `:async` adapter is suitable for development but never for production
- Always verify background job configuration after deployments
- Consider adding this check to your CI/CD pipeline

## References
- [Rails Guides: Active Job Basics](https://guides.rubyonrails.org/active_job_basics.html)
- [Sidekiq Wiki: Active Job](https://github.com/mperham/sidekiq/wiki/Active-Job)
- Internal docs: `/documentation/SIDEKIQ_SETUP.md`