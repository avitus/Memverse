# Rails 7 Deployment Checklist with Active Storage Migration

## Pre-Deployment Steps

### 1. Create Comprehensive Backup

**Use the Verified Backup Script**
```bash
# Copy the script to production server
scp deployment_scripts/verified_backup.sh avitus@www.memverse.com:/tmp/

# SSH to production server
ssh avitus@www.memverse.com

# Run the backup script
chmod +x /tmp/verified_backup.sh
/tmp/verified_backup.sh
```

This script:
- Prompts for MySQL password
- Tests database connection first
- Uses `--no-tablespaces` to avoid PROCESS privilege issues
- Verifies backup actually contains data
- Creates verification script to check backup integrity

### 2. Verify Backup Contents

Ensure the backup contains:
- [ ] `database_full.sql.gz` - Full database backup
- [ ] `code_backup.tar.gz` - Application code
- [ ] `paperclip_system_backup.tar.gz` - Sermon MP3 files
- [ ] `ckeditor_assets_backup.tar.gz` - CKEditor images/attachments
- [ ] `backup_info.txt` - Backup metadata

### 3. Test Active Storage Migration (DRY RUN)

```bash
# On production server
cd /home/avitus/memverse.com/current

# Count files that need migration
bundle exec rails runner "puts 'Sermons with MP3s: ' + Sermon.where.not(mp3_file_name: nil).count.to_s" RAILS_ENV=production
bundle exec rails runner "puts 'CKEditor Pictures: ' + Ckeditor::Picture.where.not(data_file_name: nil).count.to_s" RAILS_ENV=production
bundle exec rails runner "puts 'CKEditor Attachments: ' + Ckeditor::AttachmentFile.where.not(data_file_name: nil).count.to_s" RAILS_ENV=production

# Get MySQL password from Rails secrets (for manual backup if needed)
bundle exec rails runner "puts Rails.application.secrets[:mysql]" RAILS_ENV=production
```

## Deployment Steps

### 4. Deploy Rails 7 Code

```bash
# From local machine
bundle exec cap production deploy
```

### 5. Run Active Storage Migration (BEFORE database migration!)

```bash
# On production server
cd /home/avitus/memverse.com/current

# Run the Paperclip to Active Storage migration
bundle exec rake paperclip:migrate_to_active_storage RAILS_ENV=production

# Verify the migration
bundle exec rake paperclip:verify_migration RAILS_ENV=production
```

### 6. Run Database Migrations

Only after Active Storage migration succeeds:
```bash
# This removes Paperclip columns
bundle exec rails db:migrate RAILS_ENV=production
```

### 7. Clear Cache and Restart Services

```bash
# Clear Rails cache
bundle exec rails r "Rails.cache.clear" RAILS_ENV=production

# Restart application
# (Your specific restart command here - passenger, puma, etc.)
```

## Post-Deployment Verification

### 8. Verify Application Health

```bash
# Check application status
curl -I https://www.memverse.com

# Check Sidekiq
bundle exec rails c production
> Sidekiq::Queue.all.map(&:size)
> exit
```

### 9. Test File Accessibility

In production console:
```ruby
# Test a few sermon MP3s
Sermon.where.not(mp3_file_name: nil).limit(5).each do |s|
  puts "Sermon #{s.id}: #{s.mp3_attachment.attached? ? 'OK' : 'MISSING'}"
end

# Test CKEditor images
Ckeditor::Picture.limit(5).each do |p|
  puts "Picture #{p.id}: #{p.data_attachment.attached? ? 'OK' : 'MISSING'}"
end
```

### 10. Monitor Logs

```bash
# Watch for errors
tail -f log/production.log | grep -i error
```

## Rollback Procedure (If Needed)

### Quick Rollback (before removing Paperclip columns)
```bash
# Rollback code
bundle exec cap production deploy:rollback
```

### Full Rollback (after database migration)
```bash
# 1. Restore database from backup
cd /var/backups/memverse/latest_rails7_backup
gunzip < database_full.sql.gz | mysql -u memverse -p memverse_production

# 2. Restore code
cd /home/avitus/memverse.com
tar -xzf /var/backups/memverse/latest_rails7_backup/code_backup.tar.gz

# 3. Restart services
```

## Important Notes

1. **DO NOT** run `remove_paperclip_columns` migration before Active Storage migration
2. **DO NOT** run `paperclip:cleanup` until fully verified (this deletes original files)
3. Keep backups for at least 30 days after successful migration
4. Monitor error tracking (Sentry) closely for 24-48 hours

## Success Criteria

- [ ] All existing files accessible
- [ ] New file uploads working
- [ ] No 404s for attached files
- [ ] No errors in logs related to attachments
- [ ] Performance metrics stable or improved