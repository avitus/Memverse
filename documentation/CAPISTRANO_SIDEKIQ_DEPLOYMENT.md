# Capistrano Sidekiq Deployment Guide

This guide explains how to deploy Sidekiq with our custom scheduler/worker architecture using Capistrano.

## Architecture Overview

- **1 Scheduler Process**: Handles all cron jobs
- **3+ Worker Processes**: Handle job execution
- **Managed via systemd**: User-level services (no sudo required)
- **Integrated with Capistrano**: Automatic restart on deployment

## Initial Setup (One-time on Production Server)

### 1. Create User Systemd Directory

```bash
ssh avitus@www.memverse.com
mkdir -p ~/.config/systemd/user
```

### 2. Install Service Files

Copy the service files to the user systemd directory:

```bash
# From your local machine
scp deployment_scripts/sidekiq-scheduler.service avitus@www.memverse.com:~/.config/systemd/user/
scp deployment_scripts/sidekiq-workers@.service avitus@www.memverse.com:~/.config/systemd/user/
```

### 3. Enable Lingering (allows services to run without active session)

```bash
ssh avitus@www.memverse.com
sudo loginctl enable-linger avitus
```

### 4. Reload and Enable Services

```bash
ssh avitus@www.memverse.com
systemctl --user daemon-reload

# Enable services to start on boot
systemctl --user enable sidekiq-scheduler
systemctl --user enable sidekiq-workers@1
systemctl --user enable sidekiq-workers@2
systemctl --user enable sidekiq-workers@3

# Start services
systemctl --user start sidekiq-scheduler
systemctl --user start sidekiq-workers@{1..3}
```

## Capistrano Integration

### Standard Deployment

The standard deployment will automatically:
1. Put Sidekiq in quiet mode (stop accepting new jobs)
2. Wait for current jobs to finish
3. Restart all Sidekiq services after deployment

```bash
cap production deploy
```

### Deployment with Custom Worker Count

```bash
SIDEKIQ_WORKERS=4 cap production deploy
```

### Zero-Downtime Deployment (Rolling Restart)

```bash
SIDEKIQ_DEPLOY_STRATEGY=rolling cap production deploy
```

## Available Capistrano Tasks

### Check Status
```bash
cap production sidekiq:status
```

### Manual Restart
```bash
cap production sidekiq:restart
```

### Rolling Restart (Zero Downtime)
```bash
cap production sidekiq:rolling_restart
```

### Stop All Services
```bash
cap production sidekiq:stop
```

### Start All Services
```bash
cap production sidekiq:start
```

### Put in Quiet Mode
```bash
cap production sidekiq:quiet
```

## Configuration Files

### Scheduler Configuration (`config/sidekiq_scheduler.yml`)
- Low concurrency (5 threads)
- Loads cron jobs
- Handles scheduler queue

### Worker Configuration (`config/sidekiq_workers.yml`)
- High concurrency (25 threads)
- Does NOT load cron jobs
- Handles main queues

### Capistrano Configuration

In `config/deploy/production.rb`:
```ruby
# Disable default sidekiq hooks
set :sidekiq_default_hooks, false

# Number of worker processes
set :sidekiq_workers, 3
```

## Monitoring

### View Logs During Deployment

```bash
# In another terminal during deployment
ssh avitus@www.memverse.com
journalctl --user -f -u sidekiq-scheduler
journalctl --user -f -u sidekiq-workers@1
```

### Check Cron Jobs

```bash
ssh avitus@www.memverse.com
cd memverse.com/current
bundle exec rails c
> Sidekiq::Cron::Job.all.map(&:name)
```

Should show each job only once:
```ruby
["schedule_knowledge_quiz_tuesday", "schedule_knowledge_quiz_saturday", ...]
```

### Verify Single Scheduler

Check logs after deployment:
```bash
ssh avitus@www.memverse.com
journalctl --user -u sidekiq-scheduler | grep "SCHEDULER"
# Should see: "[SIDEKIQ SCHEDULER] Loaded X scheduled jobs"

journalctl --user -u sidekiq-workers@1 | grep "WORKER"  
# Should see: "[SIDEKIQ WORKER] This process will NOT handle cron jobs"
```

## Troubleshooting

### Services Not Starting

1. Check service status:
```bash
systemctl --user status sidekiq-scheduler
systemctl --user status sidekiq-workers@1
```

2. Check logs:
```bash
journalctl --user -xe -u sidekiq-scheduler
```

3. Verify working directory exists:
```bash
ls -la ~/memverse.com/current
```

### Cron Jobs Not Running

1. Verify scheduler is running:
```bash
systemctl --user status sidekiq-scheduler
```

2. Check if jobs are loaded:
```bash
cd ~/memverse.com/current
bundle exec rails c
> Sidekiq::Cron::Job.all
```

3. Check scheduler logs:
```bash
journalctl --user -u sidekiq-scheduler | grep "quiz"
```

### Permission Issues

If you see permission errors:
1. Ensure files are owned by correct user
2. Check systemd service user matches deployment user
3. Verify RVM permissions

### Manual Service Management

```bash
# Stop all
systemctl --user stop sidekiq-scheduler sidekiq-workers@{1..3}

# Start all
systemctl --user start sidekiq-scheduler sidekiq-workers@{1..3}

# Restart specific worker
systemctl --user restart sidekiq-workers@2

# Check all sidekiq services
systemctl --user status 'sidekiq-*'
```

## Benefits of This Setup

1. **No Duplicate Jobs**: Only scheduler loads cron
2. **Zero-Downtime Deploys**: Rolling restart option
3. **Auto-restart on Deploy**: Integrated with Capistrano
4. **No Sudo Required**: User-level systemd services
5. **Easy Scaling**: Add/remove workers as needed
6. **Better Resource Usage**: Optimized concurrency per process type

## Rollback to Old Setup

If needed, you can rollback to single Sidekiq process:

1. Stop new services:
```bash
systemctl --user stop sidekiq-scheduler sidekiq-workers@{1..3}
systemctl --user disable sidekiq-scheduler sidekiq-workers@{1..3}
```

2. Re-enable old Capistrano hooks in `config/deploy/production.rb`:
```ruby
# Comment out or remove:
# set :sidekiq_default_hooks, false
```

3. Deploy with standard sidekiq:
```bash
cap production deploy
```

## Deployment Flow Diagram

```
┌──────────────┐
│   Deploy     │
│   Started    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Sidekiq:quiet│ ◄── Stop accepting new jobs
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Deploy Code │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Published  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│Sidekiq:restart│ ◄── Restart with new code
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Finished   │
└──────────────┘
```

## Next Steps

After initial setup:
1. Deploy with `cap production deploy`
2. Monitor next quiz execution (Tuesday/Saturday)
3. Verify only 2 tweets created (start + winner)
4. Check logs for any errors