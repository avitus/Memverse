# Postmark Streams Configuration

## Overview
This document describes the Postmark message stream configuration for the Memverse application, implemented on September 2, 2025.

## Message Streams

The application uses four distinct Postmark message streams to organize email delivery:

### 1. **Outbound Stream** (Default)
- **Purpose**: Transactional emails
- **Emails**:
  - Account activation (`activation`) - includes welcome content as of Sep 3, 2025
  - ~~Signup notifications (`signup_notification`)~~ - DEPRECATED Sep 3, 2025
  - Onboarding reminders (`onboarding_reminder`)

### 2. **Broadcast Stream**
- **Purpose**: Bulk/marketing emails
- **Emails**:
  - Newsletters (`newsletter_email`)

### 3. **Reminder Stream** (Custom)
- **Stream ID**: `reminder-stream`
- **Purpose**: Memorization reminder emails
- **Emails**:
  - Progression emails 2-9 (`progression_email_2` through `progression_email_9`)
  - These are the spaced repetition reminder emails sent to users

### 4. **Forum Stream** (Custom)
- **Stream ID**: `forum-stream`
- **Purpose**: Forum notification emails
- **Emails**:
  - All Thredded forum notifications
  - Topic replies
  - Private messages
  - @mentions

## Implementation Details

### UserMailer Changes
- Updated all progression emails (2-9) to use the `reminder-stream` message stream
- Each email maintains its specific tag (e.g., `progression-9`)
- Test environment headers are properly set for compatibility

### Thredded Integration
- Created initializer at `config/initializers/postmark_streams.rb`
- Overrides `Thredded::BaseMailer#mail` method to inject `forum-stream` stream
- All forum emails automatically tagged as `forum-notification`

### Testing
- Full test coverage maintained
- Created `spec/mailers/postmark_streams_spec.rb` to verify stream assignments
- Updated existing tests in `postmark_integration_spec.rb`
- All 92 mailer tests passing

## Files Modified

1. **app/mailers/user_mailer.rb**
   - Changed progression emails from `broadcast` to `reminder-stream`

2. **config/initializers/postmark_streams.rb** (New)
   - Configures Thredded mailers to use `forum-stream`

3. **spec/mailers/postmark_streams_spec.rb** (New)
   - Tests for stream configuration

4. **spec/mailers/postmark_integration_spec.rb**
   - Updated tests to expect `reminder-stream` for progression emails

## Postmark Setup Required

In your Postmark account, ensure these message streams are created with the exact IDs:
1. `outbound` - Usually exists by default
2. `broadcast` - May need to be created
3. `reminder-stream` - Custom stream (must be created with this exact ID)
4. `forum-stream` - Custom stream (must be created with this exact ID)

## Benefits

- **Better Email Organization**: Emails are categorized by purpose
- **Improved Analytics**: Track performance metrics per stream
- **Compliance**: Different unsubscribe rules can be applied per stream
- **Deliverability**: ISPs can better understand email intent

## Deprecation Notes

### Deprecated Email Tags (as of Sep 3, 2025)
- **`signup-notification`**: This email has been deprecated to reduce email volume during user onboarding. The welcome content has been merged into the `activation` email. The UserMailer method remains for backward compatibility but is no longer called.

## Future Considerations

- Consider moving other reminder-type emails to the `reminder` stream
- Monitor stream performance in Postmark dashboard
- Adjust stream configurations based on delivery metrics
- Remove deprecated signup_notification code after confirming no issues (target: Q4 2025)