# Capistrano Rails 7 Deployment Checklist

## Pre-Deployment (On Production Server)

### 1. MySQL Version Check
```bash
# SSH to production
ssh avitus@www.memverse.com

# Check MySQL version
mysql --version

# Must be MySQL 5.7+ or MariaDB 10.2+
# If not, upgrade MySQL FIRST!
```

### 2. Install Ruby 3.2.6
```bash
# From your local machine
cap production rails7:install_ruby

# Or manually on production:
rvm install 3.2.6
rvm use 3.2.6 --default
gem install bundler
```

### 3. Verify Prerequisites
```bash
# From local machine
cap production rails7:check_prerequisites
```

## Deployment Process

### 1. Create Backup
```bash
# Critical - do not skip!
cap production rails7:backup
```

### 2. Deploy Rails 7
```bash
# Full deployment with all safety checks
cap production rails7:deploy

# Or use the wrapper script:
./deployment_scripts/capistrano_deploy.sh
```

### 3. Monitor Deployment
In another terminal:
```bash
# Watch logs
cap production logs:tail

# Or SSH and monitor directly:
ssh avitus@www.memverse.com
tail -f /home/avitus/memverse.com/current/log/production.log
```

## Post-Deployment

### 1. Verify Deployment
```bash
# Automated checks
cap production rails7:verify

# Check services
cap production deploy:status

# Check Sidekiq
cap production sidekiq:stats
```

### 2. Manual Testing
- [ ] Homepage loads
- [ ] User can login
- [ ] Verse memorization works
- [ ] File uploads work (Active Storage)
- [ ] Background jobs processing
- [ ] API endpoints respond

### 3. Monitor Performance
- [ ] Check New Relic
- [ ] Check Sentry/Airbrake for errors
- [ ] Monitor server resources

## Rollback Procedures

### Option 1: Standard Capistrano Rollback
```bash
# Rolls back to previous release
cap production deploy:rollback
```

### Option 2: Emergency Rollback
```bash
# Full rollback including database
cap production rails7:rollback_emergency
```

### Option 3: Manual Rollback
```bash
# SSH to production
ssh avitus@www.memverse.com

# Switch to previous release
cd /home/avitus/memverse.com
rm current
ln -s releases/20250809XXXXXX current

# Restart services
touch current/tmp/restart.txt
sudo systemctl restart sidekiq
```

## Troubleshooting

### Asset Compilation Issues
```bash
# Recompile assets
cap production deploy:assets:precompile

# Or manually:
cd /home/avitus/memverse.com/current
RAILS_ENV=production bundle exec rails assets:precompile
```

### Migration Issues
```bash
# Check migration status
cap production deploy:migrate:status

# Run migrations manually
cd /home/avitus/memverse.com/current
RAILS_ENV=production bundle exec rails db:migrate
```

### Bundler Issues
```bash
# Clear bundler cache
cap production bundler:clean

# Reinstall gems
cd /home/avitus/memverse.com/current
bundle install --deployment --without development test
```

## Important File Locations

- Application: `/home/avitus/memverse.com/current`
- Logs: `/home/avitus/memverse.com/shared/log/`
- Uploads: `/home/avitus/memverse.com/shared/public/uploads`
- Configs: `/home/avitus/memverse.com/shared/config/`

## Capistrano Commands Reference

```bash
# Deployment
cap production deploy
cap production deploy:rollback
cap production deploy:rollback_to_release RELEASE=20250809123456

# Maintenance
cap production deploy:web:enable  # Enable maintenance mode
cap production deploy:web:disable # Disable maintenance mode

# Rails
cap production rails:console
cap production rails:db:migrate
cap production rails:db:rollback

# Logs
cap production logs:tail
cap production logs:tail[rails]
cap production logs:tail[sidekiq]

# Services
cap production sidekiq:start
cap production sidekiq:stop
cap production sidekiq:restart

# Custom Rails 7 tasks
cap production rails7:check_prerequisites
cap production rails7:backup
cap production rails7:install_ruby
cap production rails7:deploy
cap production rails7:verify
cap production rails7:rollback_emergency
```