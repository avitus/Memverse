# Temporary Email Reminder Disablement

**Date:** August 13, 2025  
**Reason:** Email provider transition  
**Status:** DISABLED

## What Was Changed

The `SendReminders` worker has been temporarily modified to skip sending all reminder emails while maintaining user cleanup functionality.

### Changes Made

1. **File Modified:** `app/workers/send_reminders.rb`
   - Added early return with feature flag at the beginning of `perform` method
   - All email sending is bypassed

### How It Works

```ruby
def perform
  # TEMPORARY: Disable reminder emails while email provider transition is in progress
  # To re-enable: Comment out or remove the following lines
  if true  # Set to false to re-enable emails
    Rails.logger.info(" *** Email reminder: TEMPORARILY DISABLED - Skipping email reminders")

    
    return
  end
  
  # ... rest of the email sending logic ...
end
```

## To Re-Enable Emails

Choose one of these options:

### Option 1: Change the flag (Quick toggle)
```ruby
if false  # Set to false to re-enable emails
```

### Option 2: Comment out the block
```ruby
# if true  # Set to false to re-enable emails
#   Rails.logger.info(" *** Email reminder: TEMPORARILY DISABLED - Skipping email reminders")
#   
#   # Still perform user cleanup
#   User.pending.where('created_at < ?', 2.days.ago ).delete_all
#   
#   return
# end
```

### Option 3: Remove the entire block
Delete lines 8-17 from `app/workers/send_reminders.rb`

## What Still Runs

Even with emails disabled:
- The worker still runs on its hourly schedule
- Inactive pending users (2+ days old) are still deleted
- Logging indicates the disabled state
- No errors are thrown

## Monitoring

Check the logs to confirm the worker is running but skipping emails:
```bash
grep "TEMPORARILY DISABLED" log/sidekiq.log
```

You should see entries like:
```
*** Email reminder: TEMPORARILY DISABLED - Skipping email reminders
```

## Email Types Affected

All progression emails are disabled:
- progression_email_9: Users who have memorized one or more verses
- progression_email_8: Users who have completed 3 or more sessions
- progression_email_7: Users who have completed 2 sessions
- progression_email_6: Users who have completed 1 session
- progression_email_5: Users who have reviewed at least one verse
- progression_email_4: Users who have added > 5 verses
- progression_email_3: Users who have added 1-5 verses
- progression_email_2: Users who have confirmed account but added no verses

## Other Email Systems

This change ONLY affects the `SendReminders` worker. Other email systems remain active:
- Account activation emails
- Password reset emails
- Admin notifications
- Quiz announcements
- Any other mailers

## Rollback

If you need to quickly rollback without code changes, you can:
1. Deploy the previous version of the code
2. Or use the git history to revert:
   ```bash
   git checkout HEAD~ -- app/workers/send_reminders.rb
   ```

## Notes

- This is a safe, temporary change that preserves all business logic
- No database changes are required
- The worker continues to run normally (just skips email sending)
- User cleanup functionality is preserved
- Easy to re-enable when ready