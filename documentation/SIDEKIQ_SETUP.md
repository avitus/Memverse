# Sidekiq Automatic Setup and Logging

## Overview
Sidekiq is now configured to start automatically with the Rails application and log all output to `log/sidekiq.log`.

## Configuration Changes

### 1. **Procfile Updated**
```
web:    rails s
worker: bundle exec sidekiq -C config/sidekiq.yml
redis:  redis-server
```

### 2. **Sidekiq Initializer Enhanced**
- Configured to always write to `log/sidekiq.log`
- In development: logs to both file and stdout
- In production: logs to file only with JSON formatting
- Custom MultiLogger class handles dual logging

### 3. **New Development Script**
Created `bin/dev` to start all processes together.

## Usage

### Starting Everything at Once
```bash
# Recommended way to start development environment
./bin/dev

# This starts:
# - Rails server on port 3000
# - Sidekiq worker (logs to log/sidekiq.log)
# - Redis server
```

### Starting Components Individually
```bash
# Rails only
rails s

# Sidekiq only (will log to log/sidekiq.log)
bundle exec sidekiq -C config/sidekiq.yml

# Redis only
redis-server
```

### Monitoring Logs

#### Real-time Sidekiq Logs
```bash
# Follow all Sidekiq logs
tail -f log/sidekiq.log

# Watch for quiz-related logs
tail -f log/sidekiq.log | grep -i quiz

# Watch for errors only
tail -f log/sidekiq.log | grep -E "ERROR|WARN"
```

#### Combined Log Monitoring
```bash
# Watch both Rails and Sidekiq logs
tail -f log/development.log log/sidekiq.log
```

## Features

### Automatic Log File Creation
- The `bin/dev` script ensures `log/sidekiq.log` exists
- No manual log file creation needed

### Foreman Process Management
- Uses foreman gem to manage multiple processes
- Graceful shutdown with Ctrl-C stops all processes
- Automatic installation if foreman is missing

### Redis Check
- Automatically starts Redis if not running
- Prevents "connection refused" errors

### Development-Friendly
- In development, Sidekiq logs appear in both:
  - Terminal (for immediate visibility)
  - `log/sidekiq.log` (for grep/analysis)

## Production Deployment
For production, use systemd or another process manager. Example systemd service:

```ini
[Unit]
Description=Sidekiq for Memverse
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/path/to/memverse
ExecStart=/usr/local/bin/bundle exec sidekiq -C config/sidekiq.yml
User=deploy
Group=deploy
UMask=0002
RestartSec=1
Restart=on-failure
StandardOutput=append:/path/to/memverse/log/sidekiq.log
StandardError=append:/path/to/memverse/log/sidekiq.log

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

### Sidekiq Not Logging
Check that `log/sidekiq.log` exists and has write permissions:
```bash
touch log/sidekiq.log
chmod 666 log/sidekiq.log
```

### Foreman Not Found
The `bin/dev` script will automatically install foreman, but you can manually install:
```bash
gem install foreman
```

### Port Already in Use
If port 3000 is taken:
```bash
# Kill existing Rails server
lsof -ti:3000 | xargs kill -9

# Or use a different port
rails s -p 3001
```