# Quick Rails 7 Deployment with Capistrano

## 🚀 Fastest Path (If Everything is Ready)

```bash
# 1. Run the automated deployment script
cd /path/to/memverse
./deployment_scripts/capistrano_deploy.sh

# Or manually:
bundle exec cap production rails7:deploy
```

## 📋 Pre-Deployment Commands

```bash
# Check if production is ready
cap production rails7:check_prerequisites

# Install Ruby 3.2.6 if needed
cap production rails7:install_ruby

# Create backup (NEVER SKIP!)
cap production rails7:backup
```

## 🔧 During Deployment

Monitor in another terminal:
```bash
# Option 1: Via Capistrano
cap production logs:tail

# Option 2: Direct SSH
ssh avitus@www.memverse.com
tail -f /home/avitus/memverse.com/current/log/production.log
```

## ✅ Post-Deployment

```bash
# Verify deployment
cap production rails7:verify

# Check Sidekiq
cap production sidekiq:stats

# Open Rails console if needed
cap production rails:console
```

## 🚨 Emergency Procedures

```bash
# Quick rollback to previous release
cap production deploy:rollback

# Full emergency rollback (includes DB)
cap production rails7:rollback_emergency

# Manual service restart
cap production sidekiq:restart
```

## 🎯 One-Liner Deploy Commands

```bash
# Full deployment with all checks
cap production rails7:deploy

# Deploy without migrations
cap production deploy deploy:migrate='false'

# Deploy specific branch
cap production deploy BRANCH=rails-7-upgrade

# Deploy with verbose output
cap production deploy --trace
```

## 📊 Status Checks

```bash
# What's currently deployed?
cap production deploy:current

# List all releases
cap production deploy:releases

# Check pending migrations
cap production deploy:migrate:status
```

## 🛠️ Common Fixes

```bash
# Asset issues
cap production deploy:assets:precompile

# Bundle issues
cap production bundler:install

# Permission issues
cap production deploy:set_permissions

# Clear caches
cap production rails:cache:clear
```

## 💡 Pro Tips

1. **Always backup first**: `cap production rails7:backup`
2. **Test connection**: `cap production deploy:check`
3. **Dry run**: `cap production deploy --dry-run`
4. **Watch multiple logs**: `cap production logs:tail[rails,sidekiq,nginx]`
5. **Keep the old branch**: Don't delete `upgrade-2026` until Rails 7 is stable

## 📱 Update Production Branch After Success

```bash
# After successful deployment and testing
git checkout master
git merge rails-7-upgrade
git push origin master

# Update deploy config
# Edit config/deploy/production.rb
# Change: set :branch, 'master'
```

---

**Remember**: The Rails 7 upgrade includes:
- Ruby 2.7.8 → 3.2.6
- Rails 5.x → 7.0
- Paperclip → Active Storage
- MySQL must be 5.7+