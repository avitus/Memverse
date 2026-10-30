# Archived: Memverse Rails 7 Deployment Guide (August 2025)

> **Do not follow the deployment, rollback or monitoring steps below.** They describe the one-off
> August 2025 Rails 7 cut-over and are kept only as a record of it. The current procedure is
> [documentation/DEPLOYMENT.md](../documentation/DEPLOYMENT.md): `cap production deploy` from `main`
> with Rails encrypted credentials. The files in this directory that are still in use are the Sidekiq
> systemd units (`sidekiq-scheduler.service`, `sidekiq-workers@.service`, `setup_sidekiq_services.sh`),
> `verified_backup.sh`, and the `migration/` directory from the October 2026 server move.

This guide provided step-by-step instructions for deploying the Rails 7 upgrade to production using Capistrano.

## 🔐 Database Configuration Update

**Important**: As of Rails 7.1, we use Rails encrypted credentials for database configuration instead of a shared database.yml file. This provides:
- Encrypted storage of sensitive data
- Version-controlled configuration
- No plaintext passwords on servers

See `documentation/DEPLOYMENT.md` (the current deployment guide) for setup instructions.

## 🚨 CRITICAL REQUIREMENTS

Before starting, you MUST verify:

1. **MySQL Version**: Production must have MySQL 5.7+ or MariaDB 10.2+
2. **SSH Access**: You can SSH to production as the deploy user
3. **Backup Storage**: At least 10GB free space for backups
4. **Maintenance Window**: 30-45 minutes of planned downtime

## 📋 Pre-Deployment Checklist

Complete ALL items before proceeding:

- [ ] `main` is up to date and CI is green (Capistrano deploys `main`; see `config/deploy.rb`)
- [ ] Recent production backup exists (< 24 hours old)
- [ ] Team is notified of maintenance window
- [ ] Error tracking (Sentry/Airbrake) is monitored
- [ ] You have rollback plan ready

## 🎯 Step-by-Step Deployment Instructions

### Step 1: Setup Local Environment

```bash
# Navigate to your local Memverse directory
cd /path/to/memverse

# Ensure you're on main
git checkout main
git pull origin main

# Install deployment dependencies
bundle install

# Make scripts executable
chmod +x deployment_scripts/*.sh
```

### Step 2: Add Capistrano Rails 7 Tasks

```bash
# Copy the Rails 7 tasks to Capistrano tasks directory
cp lib/capistrano/tasks/rails7_upgrade.rake lib/capistrano/tasks/

# Edit your Capfile and add this line after other requires:
echo "Dir.glob('lib/capistrano/tasks/rails7*.rake').each { |r| import r }" >> Capfile
```

### Step 3: Verify Production Prerequisites

```bash
# Check if production meets all requirements
bundle exec cap production rails7:check_prerequisites
```

**If MySQL is too old** (< 5.7):
```bash
# DO NOT PROCEED! Upgrade MySQL first.
# SSH to production and upgrade MySQL before continuing
```

**If Ruby 3.2.6 is not installed**:
```bash
# Install Ruby 3.2.6 on production
bundle exec cap production rails7:install_ruby

# Verify installation
bundle exec cap production rails7:check_prerequisites
```

### Step 4: Create Production Backup

```bash
# CRITICAL: Never skip this step!
bundle exec cap production rails7:backup

# Note the backup location that's displayed
# Example: /var/backups/memverse/rails7_upgrade_20250809_143022
```

### Step 5: Deploy Rails 7

```bash
# 1. Start monitoring in a new terminal
bundle exec cap production logs:tail

# 2. In your main terminal, run the deployment
bundle exec cap production rails7:deploy
```

### Step 6: Monitor Deployment Progress

While deployment is running, monitor in another terminal:

```bash
# Option 1: Via Capistrano
bundle exec cap production logs:tail

# Option 2: Direct SSH monitoring
ssh avitus@www.memverse.com
tail -f /home/avitus/memverse.com/current/log/production.log

# Option 3: Watch Sidekiq
bundle exec cap production sidekiq:stats
```

### Step 7: Post-Deployment Verification

```bash
# Run automated verification
bundle exec cap production rails7:verify

# Check service status
bundle exec cap production deploy:status

# Verify Sidekiq is processing jobs
bundle exec cap production sidekiq:stats
```

### Step 8: Manual Testing

Test these critical features manually:

1. **Homepage**: https://www.memverse.com
   - [ ] Loads without errors
   - [ ] CSS and JavaScript work

2. **Authentication**:
   - [ ] Login works
   - [ ] Logout works
   - [ ] Password reset works

3. **Core Features**:
   - [ ] Verse memorization works
   - [ ] Add new verse works
   - [ ] File uploads work (tests Active Storage)
   - [ ] Search functionality works

4. **API** (if applicable):
   - [ ] API endpoints respond
   - [ ] Authentication works

### Step 9: Update Deployment Configuration

After successful deployment and testing:

Nothing to change: `config/deploy.rb` already deploys `main` and `config/deploy/production.rb` targets martial-eagle. (`config/deploy/production_rails7.rb` is a leftover from the upgrade and is not used.)

## 🚨 Emergency Rollback Procedures

If anything goes wrong, rollback immediately:

### Quick Rollback (Code Only)
```bash
# Rolls back to previous release
bundle exec cap production deploy:rollback
```

### Full Emergency Rollback (Code + Database)
```bash
# Complete rollback including database restoration
bundle exec cap production rails7:rollback_emergency
```

### Manual Rollback
```bash
# 1. SSH to production
ssh avitus@www.memverse.com

# 2. Check releases
ls -la /home/avitus/memverse.com/releases/

# 3. Link to previous release
cd /home/avitus/memverse.com
rm current
ln -s releases/[PREVIOUS_TIMESTAMP] current

# 4. Restart services
touch current/tmp/restart.txt
sudo systemctl restart memverse-sidekiq
```

## 📊 Monitoring Commands

```bash
# View current deployment
bundle exec cap production deploy:current

# Check logs
bundle exec cap production logs:tail
bundle exec cap production logs:tail[rails]
bundle exec cap production logs:tail[sidekiq]

# Rails console (for debugging)
bundle exec cap production rails:console

# Database migration status
bundle exec cap production deploy:migrate:status
```

## ⚠️ Common Issues and Solutions

### Issue: Assets not loading
```bash
# Recompile assets
bundle exec cap production deploy:assets:precompile
bundle exec cap production deploy:assets:clean
```

### Issue: Bundler errors
```bash
# Clear bundle and reinstall
bundle exec cap production bundler:clean
bundle exec cap production bundler:install
```

### Issue: Migration failures
```bash
# Check migration status
bundle exec cap production deploy:migrate:status

# Run specific migration
bundle exec cap production rails:runner CODE='ActiveRecord::Migration.run(:up, 20250807052459)'
```

### Issue: Sidekiq not processing
```bash
# Restart Sidekiq
bundle exec cap production sidekiq:restart

# Check Redis connection
bundle exec cap production rails:runner CODE='Redis.new.ping'
```

## 📝 Post-Deployment Tasks

1. **Monitor for 24 hours**:
   - Check error tracking hourly
   - Monitor server resources
   - Watch for unusual patterns

2. **Update documentation**:
   - Record deployment date and any issues
   - Update team wikis/docs

## 🔍 Verification Checklist

After deployment, verify:

- [ ] All tests from Step 8 pass
- [ ] No errors in logs for 30 minutes
- [ ] Background jobs processing normally
- [ ] Memory usage stable
- [ ] Response times normal (< 2 seconds)
- [ ] No 500 errors in monitoring
- [ ] File uploads working (Active Storage)

## 📞 Support

If you encounter issues:

1. Check logs first: `cap production logs:tail`
2. Review error tracking (Sentry/Airbrake)
3. Consult the troubleshooting section above
4. If critical: Execute rollback immediately

## 🎉 Success Criteria

The deployment is successful when:

1. All automated tests pass (`rails7:verify`)
2. Manual testing confirms all features work
3. No errors in logs for 30+ minutes
4. Background jobs processing normally
5. Performance metrics are normal or improved

---

**Remember**: Take your time, follow each step carefully, and don't skip the backup!