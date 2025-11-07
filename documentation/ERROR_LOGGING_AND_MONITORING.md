# Error Logging and Monitoring in Memverse

## Why 500 Errors May Not Appear in production.log

There are several reasons why the 500 error from blocking posts didn't appear in `/log/production.log`:

### 1. **Sentry Error Tracking (Primary Reason)**
The application uses Sentry (via the `sentry-raven` gem) for error tracking in production:

```ruby
# config/initializers/sentry.rb
Raven.configure do |config|
  config.dsn = 'https://[...]@sentry.io/299442'
  config.environments = %w[ production ]
end
```

When an unhandled exception occurs in production:
- Sentry intercepts the error before it reaches the Rails logger
- The error is sent to Sentry's servers for tracking
- The error may bypass normal Rails logging, especially if Sentry is configured to suppress duplicate logging

### 2. **Web Server Error Handling**
The production server (likely Nginx or Apache) may:
- Catch certain errors at the web server level
- Log errors to its own error log (e.g., `/var/log/nginx/error.log`)
- Return a generic 500 error page without passing the full error to Rails

### 3. **Rails Production Configuration**
In `config/environments/production.rb`:
- `config.consider_all_requests_local = false` - This prevents detailed error pages
- `config.log_level = :info` - While this should still log errors, some middleware might filter them

### 4. **Database-Level Errors**
The specific error (passing a symbol to an integer column via `update_all`) may have:
- Been caught at the MySQL adapter level
- Triggered a database constraint error that wasn't properly bubbled up to Rails logging
- Been intercepted by ActiveRecord's error handling before reaching the application logger

## Where to Find Production Errors

### 1. **Sentry Dashboard**
- Primary location: Check https://sentry.io for your project
- Contains full stack traces, error context, and frequency data
- Errors are categorized and grouped for easier debugging

### 2. **Web Server Logs**
```bash
# Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Apache
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log

# Or check systemd journal
sudo journalctl -u nginx -f
sudo journalctl -u apache2 -f
```

### 3. **System Logs**
```bash
# System messages
sudo tail -f /var/log/syslog
sudo tail -f /var/log/messages

# Application-specific
sudo journalctl -u puma -f  # or your app server
```

### 4. **Database Logs**
```bash
# MySQL/MariaDB
sudo tail -f /var/log/mysql/error.log
sudo tail -f /var/log/mysql/mysql.log
```

### 5. **Rails Logs with Different Verbosity**
Sometimes errors are logged but not where expected:
```bash
# Check all Rails logs
tail -f log/production.log | grep -i error
tail -f log/production.log | grep -i exception
tail -f log/production.log | grep -i mysql2
```

## Improving Error Visibility

### 1. **Test Error Logging**
Add temporary debugging to ensure errors are being logged:
```ruby
# In ApplicationController
rescue_from StandardError do |exception|
  Rails.logger.error "Unhandled error: #{exception.class} - #{exception.message}"
  Rails.logger.error exception.backtrace.join("\n")
  Raven.capture_exception(exception)
  raise
end
```

### 2. **Configure Sentry to Also Log Locally**
Ensure Sentry doesn't suppress local logging:
```ruby
Raven.configure do |config|
  # ... existing config ...
  config.silence_ready = false
  config.before_send = lambda do |event, hint|
    Rails.logger.error "Sentry Error: #{event}"
    event
  end
end
```

### 3. **Add Request Logging**
For better debugging context:
```ruby
# config/environments/production.rb
config.log_tags = [:request_id, :remote_ip, lambda { |req| req.session[:user_id] }]
```

### 4. **Monitor Multiple Sources**
Set up log aggregation to monitor all error sources:
- Use tools like Logstash, Fluentd, or CloudWatch
- Aggregate web server, Rails, and system logs
- Set up alerts for 5xx status codes

## Best Practices

1. **Always check Sentry first** for application errors in production
2. **Set up error notifications** in Sentry for critical errors
3. **Use structured logging** to make errors easier to find and parse
4. **Test error handling** in staging environment before production
5. **Keep logs centralized** for easier debugging across services
6. **Monitor response codes** at the web server level for 500 errors

## The Specific Blocking Error

The error when blocking posts was likely:
- Caught by Sentry and visible in the Sentry dashboard
- A MySQL type mismatch error when trying to insert symbol `:blocked` into integer column
- Possibly logged to MySQL error log or web server error log
- Not propagated to Rails production.log due to Sentry interception