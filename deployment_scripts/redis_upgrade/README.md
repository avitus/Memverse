# Redis Upgrade Guide: 3.2.1 → 6.2

## Overview
This guide upgrades Redis from the very old 3.2.1 (2016) to 6.2 (2021) to fix compatibility issues with the `redis-client` gem that requires Redis 6.0+.

## Why This Upgrade?
- **Current Issue**: `RedisClient::UnsupportedServer: redis-client requires Redis 6+ with HELLO command`
- **Root Cause**: Redis 3.2.1 doesn't support the HELLO command introduced in Redis 6.0
- **Impact**: Users cannot mark verses as tested, breaking core functionality

## Pre-Upgrade Checklist
- [ ] Schedule maintenance window (10-15 minutes expected)
- [ ] Notify users of brief downtime
- [ ] Ensure you have sudo access on the server
- [ ] Make scripts executable: `chmod +x *.sh`

## Upgrade Steps

### 1. Pre-Upgrade Check
```bash
./01_pre_upgrade_check.sh
```
This will show:
- Current Redis version (should be 3.2.1)
- Sidekiq queue sizes
- Active quiz/chat sessions
- Memory usage

### 2. Drain Sidekiq Queues
```bash
./02_drain_sidekiq.sh
```
This will:
- Put Sidekiq in quiet mode (stop accepting new jobs)
- Wait for all queues to empty
- Stop Sidekiq service

### 3. Perform Redis Upgrade
```bash
sudo ./03_upgrade_redis.sh
```
This will:
- Add Redis 6.2 repository
- Stop Redis 3.2.1
- Backup old binaries
- Install Redis 6.2
- Update configuration
- Start Redis 6.2
- Verify HELLO command works

### 4. Post-Upgrade Verification
```bash
./04_post_upgrade_verify.sh
```
This will:
- Check Redis health
- Test Redis operations
- Start Sidekiq
- Verify Rails app connectivity
- Check application health

### 5. Emergency Rollback (if needed)
```bash
sudo ./05_rollback_redis.sh
```
This will:
- Restore Redis 3.2.1
- Restore old configuration
- Restart services
- **Note**: You'll need to downgrade the redis gem after rollback

## Expected Downtime
- **Sidekiq queue draining**: 1-5 minutes (depends on queue size)
- **Redis upgrade**: 2-3 minutes
- **Verification**: 2-3 minutes
- **Total**: ~10-15 minutes

## Post-Upgrade Monitoring
1. Monitor Sentry for any new Redis errors
2. Check application logs:
   ```bash
   tail -f /var/www/memverse/current/log/production.log
   ```
3. Monitor Sidekiq:
   ```bash
   sudo journalctl -u sidekiq -f
   ```
4. Test core features:
   - User login
   - Marking verses as tested
   - Background job processing

## Troubleshooting

### If Redis won't start after upgrade
1. Check logs: `sudo journalctl -u redis -n 50`
2. Check config syntax: `redis-server /etc/redis/redis.conf --test-memory 1`
3. Ensure port 6379 is not in use: `sudo netstat -tlpn | grep 6379`

### If Sidekiq won't connect
1. Check Sidekiq logs: `sudo journalctl -u sidekiq -n 50`
2. Verify Redis is listening on localhost: `redis-cli -h localhost ping`
3. Check Redis connection in Rails console:
   ```ruby
   cd /var/www/memverse/current
   bundle exec rails console
   $redis.ping  # Should return "PONG"
   ```

### If application has Redis errors
1. Restart application server: `sudo systemctl restart passenger`
2. Clear Rails cache: `cd /var/www/memverse/current && bundle exec rails tmp:cache:clear`

## Success Criteria
- [ ] Redis version shows 6.2.x
- [ ] No errors in Sentry related to Redis
- [ ] Users can mark verses as tested
- [ ] Background jobs are processing
- [ ] Quiz and chat features work

## Alternative: Gem Downgrade (Quick Fix)
If the upgrade cannot be performed immediately, you can temporarily fix the issue by downgrading the Redis gem:

```ruby
# In Gemfile, change:
gem 'redis', '~> 5.0'
# To:
gem 'redis', '~> 4.8'

# Then run:
bundle update redis
bundle exec cap production deploy
```

However, this is a temporary solution. Redis 3.2.1 is EOL and has security vulnerabilities.