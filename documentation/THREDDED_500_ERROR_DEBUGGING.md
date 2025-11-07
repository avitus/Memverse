# Thredded Moderation 500 Error Debugging Guide

## Issue Summary

The production server returns a 500 error when attempting to block posts on `/forum/admin/moderation`, but:
- The error works fine in development
- No error appears in production.log (only "Started POST" entry)
- No error appears in Sentry
- The request dies before reaching any controller code

## Most Likely Cause: CSRF Token Verification

The application has `protect_from_forgery prepend: true` in ApplicationController, which means CSRF verification happens before all other processing. If this fails in production, it would cause exactly the symptoms we see.

## Debugging Tools Deployed

### 1. Early Middleware Logger (`01_thredded_request_logger.rb`)
- Logs at the very beginning of the middleware stack
- Shows headers, content type, and CSRF token presence
- Look for: `[EARLY MIDDLEWARE]` entries

### 2. CSRF Error Handler (`thredded_csrf_fix.rb`)
- Catches and logs CSRF verification failures
- Provides graceful error handling for moderation actions
- Look for: `[CSRF FIX]` entries

### 3. Emergency Controller Logger (`thredded_moderation_emergency_fix.rb`)
- Logs when moderate_post action is called
- Shows params structure
- Catches and logs any controller-level errors
- Look for: `[EMERGENCY FIX]` entries

### 4. Test Endpoint (`thredded_test_action.rb`)
- Provides `/forum/admin/moderation/test` endpoint
- Bypasses CSRF verification
- If this works, confirms CSRF is the issue

## What to Check After Deployment

### 1. Server Restart Required
```bash
# The middleware and initializers require a server restart
sudo systemctl restart puma  # or your app server
```

### 2. Check Startup Logs
Look for these confirmation messages:
- `[STARTUP] Early middleware for Thredded moderation logging installed`
- `[CSRF FIX] All CSRF fixes loaded`
- `[EMERGENCY FIX] Patch applied successfully`

### 3. Test the Debug Endpoint
```bash
# This bypasses CSRF to verify basic functionality
curl -X POST https://www.memverse.com/forum/admin/moderation/test \
  -H "Cookie: YOUR_SESSION_COOKIE" \
  -d "test=true"
```

If this returns JSON with "status: ok", the issue is definitely CSRF-related.

### 4. Try Blocking a Post
When you try to block a post normally, check logs for:

```bash
# Look for early middleware logs
grep "EARLY MIDDLEWARE" /path/to/production.log

# Look for CSRF errors
grep "CSRF FIX" /path/to/production.log

# Look for emergency fix logs
grep "EMERGENCY FIX" /path/to/production.log
```

### 5. Check Debug Status
Visit: `https://www.memverse.com/debug/thredded_status`

This shows:
- Whether Thredded modules are loaded
- Available moderation states
- Whether optimizations are loaded

## Interpreting Results

### If you see `[EARLY MIDDLEWARE]` but no controller logs:
- CSRF token is missing or invalid
- Authentication is failing
- Route constraints are failing

### If you see `[CSRF FIX] Invalid authenticity token`:
- Confirms CSRF is the issue
- Check if CSRF tokens are being included in forms
- May need to update form to include proper tokens

### If test endpoint works but normal endpoint doesn't:
- Definitely CSRF issue
- Need to fix CSRF token generation/validation

## Permanent Fix Options

Once we identify the exact issue, options include:

1. **Fix CSRF token generation** in Thredded forms
2. **Skip CSRF for moderation actions** (if user is authenticated admin)
3. **Use API tokens** instead of session-based auth for moderation
4. **Update Thredded gem** if this is a known issue

## Emergency Workaround

If needed, you can temporarily disable CSRF for moderation:

```ruby
# In thredded_csrf_fix.rb, add:
skip_before_action :verify_authenticity_token, only: [:moderate_post]
```

But only do this as a last resort after confirming the user is authenticated.