# Reminder Email Processing Order

## Overview
Updated the `SendReminders` Sidekiq worker to process users from newest to oldest (by registration date) when sending reminder emails.

## Changes Made

### 1. Modified Processing Order
**File**: `app/workers/send_reminders.rb`

Changed from:
```ruby
User.find_each { |u|
  # Process users
}
```

To:
```ruby
User.order(created_at: :desc).in_batches(of: 1000) do |batch|
  batch.each do |u|
    # Process users
  end
end
```

### Key Details:
- **`order(created_at: :desc)`**: Orders users by registration date, newest first
- **`in_batches(of: 1000)`**: Processes users in batches of 1000 for efficiency
- **Why not `find_each`?**: The `find_each` method ignores custom ordering for performance reasons, so we use `in_batches` instead

## Benefits

1. **Prioritizes New Users**: Recently registered users get their reminder emails first, improving their onboarding experience
2. **Better Resource Utilization**: If the email throttle limit is reached (100 emails per run), newer users are guaranteed to receive emails
3. **Improved User Retention**: New users are more likely to stay engaged when they receive timely reminders

## Performance Considerations

- `in_batches` with ordering is slightly slower than `find_each` but the difference is negligible for typical user counts
- Still processes in batches of 1000 to avoid memory issues
- The ordering happens at the database level, which is efficient

## Testing

Created comprehensive tests in:
- `spec/workers/send_reminders_spec.rb` - Updated existing tests to handle new batching method
- `spec/workers/send_reminders_newest_first_spec.rb` - New tests specifically for ordering verification

## Email Throttling

The worker has a throttle limit of 100 emails per execution. With the new ordering:
- First 100 emails go to the newest users
- Older users may need to wait for the next execution cycle
- This ensures new users always get priority

## Configuration

Currently, reminder emails are **temporarily disabled** in the worker. To re-enable:

1. Edit `app/workers/send_reminders.rb`
2. Change line 10 from `if false` to `if true` to keep them disabled
3. Or remove the entire conditional block (lines 9-13) to enable permanently

## Deployment Notes

After deployment:
1. Monitor the Sidekiq logs to verify correct ordering
2. Check that new users receive emails before older users
3. Ensure batch processing is working correctly

## Future Improvements

Consider:
- Making the batch size configurable
- Adding metrics to track email send order
- Implementing separate queues for new vs. existing users
- Adjusting throttle limits based on user registration patterns