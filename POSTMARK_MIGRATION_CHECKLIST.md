# Postmark Email Service Migration Checklist

## Pre-Deployment Steps

### 1. Postmark Account Setup
- [ ] Create Postmark account at https://postmarkapp.com
- [ ] Create a new server for Memverse
- [ ] Note the Server API Token (currently using: `6b4a7191-6750-46e4-95d9-72ad17c45156`)
- [ ] Verify domain ownership in Postmark
- [ ] Configure SPF and DKIM records for email authentication

### 2. Message Streams Configuration
- [ ] Create "outbound" message stream (default transactional stream)
- [ ] Create "broadcast" message stream for marketing/newsletter emails
- [ ] Configure appropriate settings for each stream:
  - Outbound: No unsubscribe footer (we handle it in the app)
  - Broadcast: Enable bounce/spam complaint handling

### 3. Postmark Dashboard Setup
- [ ] Set up bounce webhooks if needed
- [ ] Configure spam complaint handling
- [ ] Set up monitoring alerts for delivery issues
- [ ] Review and configure IP pools if needed

## Deployment Steps

### 1. Environment Variables
- [ ] Set `POSTMARK_API_TOKEN` environment variable on production server
- [ ] Remove any Sendgrid-related environment variables

### 2. Code Deployment
- [ ] Deploy the updated code with Postmark integration
- [ ] Verify bundle install completes successfully
- [ ] Restart application servers

### 3. Configuration Verification
- [ ] Verify ActionMailer is using `:postmark` delivery method
- [ ] Confirm API token is properly loaded
- [ ] Check Rails logs for any configuration errors

## Post-Deployment Testing

### 1. Test Email Delivery
- [ ] Send test signup email
- [ ] Send test activation email
- [ ] Send test newsletter email
- [ ] Send test progression emails
- [ ] Verify admin notification emails

### 2. Verify Email Features
- [ ] Check that tags are properly set in Postmark dashboard
- [ ] Verify message streams are correctly assigned
- [ ] Confirm unsubscribe links are working
- [ ] Test email rendering in different clients

### 3. Monitor Initial Sends
- [ ] Monitor Postmark dashboard for first hour
- [ ] Check bounce rates
- [ ] Review delivery statistics
- [ ] Verify no errors in application logs

## Rollback Plan

If issues arise:
1. Change `config.action_mailer.delivery_method` back to previous setting
2. Redeploy previous version
3. Investigate issues before retry

## Migration Summary

### What Changed
1. **Email Service**: Sendgrid → Postmark
2. **Gem**: Added `postmark-rails ~> 0.22`
3. **Configuration**: 
   - Added Postmark API token configuration
   - Updated all mailers to use Postmark tags and message streams
4. **Tags**: Migrated from `X-MC-Tags` headers to Postmark native tags
5. **Message Streams**: 
   - Transactional emails use "outbound" stream
   - Marketing/progression emails use "broadcast" stream

### Files Modified
- `Gemfile` - Added postmark-rails gem
- `config/environments/production.rb` - Postmark configuration
- `config/environments/development.rb` - Postmark configuration
- `app/mailers/user_mailer.rb` - Updated to use Postmark tags/streams
- `app/mailers/admin_mailer.rb` - Updated to use Postmark tags/streams
- `config/initializers/postmark.rb` - Postmark helper methods
- `spec/mailers/postmark_integration_spec.rb` - Updated tests

### Benefits
- Better email deliverability
- More detailed analytics and tracking
- Easier troubleshooting with tags and streams
- Better bounce and complaint handling
- Improved unsubscribe management