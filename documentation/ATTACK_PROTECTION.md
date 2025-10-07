# Attack Protection Middleware

## Overview

The `AttackProtectionMiddleware` protects the Memverse application from common web attacks by:

1. **Blocking WordPress/PHP attack paths** - Returns 404 for common WordPress, PHP admin, and attack vector paths
2. **Filtering malicious user agents** - Returns 403 for known attack tool user agents
3. **Handling IP spoofing attempts** - Gracefully catches IP spoofing errors and prevents them from reaching Sentry

## Implementation

### Location
- **Middleware**: `/app/middleware/attack_protection_middleware.rb`
- **Configuration**: `/config/initializers/attack_protection_middleware.rb`
- **Tests**:
  - Unit tests: `/spec/middleware/attack_protection_middleware_spec.rb`
  - Integration tests: `/spec/requests/attack_protection_spec.rb`

### Middleware Stack Position

The middleware is inserted **before** `ActionDispatch::RemoteIp` to intercept IP spoofing attempts before they raise errors:

```ruby
Rails.application.config.middleware.insert_before ActionDispatch::RemoteIp, AttackProtectionMiddleware
```

This positioning is critical because:
- It catches IP spoofing exceptions from the RemoteIp middleware
- It blocks malicious requests before they consume application resources
- It prevents attack-related errors from being sent to Sentry

## Protected Paths

### WordPress Attack Paths
- `/wp-login.php`
- `/wp-admin`
- `/wp-content`
- `/wp-includes`
- `/xmlrpc.php`
- `/wp-config.php`
- `/wp-cron.php`
- `/wp-load.php`
- `/wp-signup.php`

### PHP Admin Tools
- `/phpmyadmin`
- `/pma`
- `/phpMyAdmin`
- `/myadmin`
- `/mysql`
- `/dbadmin`
- `/websql`
- `/mysqladmin`

### Other Attack Vectors
- `/admin.php`
- `/administrator`
- `/config.php`
- `/database.php`
- `/.env`
- `/env`
- `/.git/config`
- `/backup.sql`
- `/wp-config.php.bak`

## Blocked User Agents

The middleware blocks requests from known attack tools including:
- sqlmap (SQL injection scanner)
- nikto (web vulnerability scanner)
- wpscan (WordPress vulnerability scanner)
- masscan (port scanner)
- nmap (network scanner)
- metasploit (penetration testing framework)
- havij (SQL injection tool)
- acunetix (vulnerability scanner)

Pattern matching is case-insensitive to catch variations like `SQLMAP`, `SqlMap`, etc.

## IP Spoofing Protection

### The Problem
Attackers send conflicting IP headers to bypass security controls:
```
HTTP_CLIENT_IP: 192.168.1.100
HTTP_X_FORWARDED_FOR: 10.0.0.1
```

When these headers conflict, Rails' `ActionDispatch::RemoteIp` middleware raises an `IpSpoofAttackError`.

### The Solution
Our middleware catches these exceptions and:
1. Logs the attempt with full details (path, user agent, IP headers)
2. Returns a 403 Forbidden response
3. Prevents the error from reaching Sentry (reducing noise)

### Logged Information
When an IP spoofing attempt is detected, the middleware logs:
- Request path
- User agent
- HTTP_CLIENT_IP value
- HTTP_X_FORWARDED_FOR value
- REMOTE_ADDR value
- Error message

## Response Codes

| Status | Reason | Description |
|--------|--------|-------------|
| 404 Not Found | Blocked Path | WordPress/PHP/attack path detected |
| 403 Forbidden | Blocked Request | Malicious user agent or IP spoofing detected |
| 200 OK | Passed | Legitimate request passed through |

All blocked responses include the `X-Attack-Protection` header indicating the block reason:
- `blocked-path` - Path was on the blocklist
- `blocked-request` - User agent or IP spoofing detected

## Logging Behavior

### WordPress/PHP Path Blocking
```
Blocked attack path: /wp-login.php from 203.0.113.1
```

### Malicious User Agent Blocking
```
Blocked malicious user agent: sqlmap/1.0 from 203.0.113.1
```

### IP Spoofing Attempts
```
IP Spoofing attempt detected:
Path: /users
User-Agent: BadBot/1.0
HTTP_CLIENT_IP: 192.168.1.100
HTTP_X_FORWARDED_FOR: 10.0.0.1
REMOTE_ADDR: 203.0.113.1
Error: IP spoofing attack?! HTTP_CLIENT_IP="192.168.1.100" HTTP_X_FORWARDED_FOR="10.0.0.1"
```

## Testing

### Unit Tests (40 examples)
```bash
bundle exec rspec spec/middleware/attack_protection_middleware_spec.rb
```

Tests cover:
- WordPress/PHP path blocking (12 tests)
- Malicious user agent detection (8 tests)
- IP spoofing protection (7 tests)
- Logging behavior (3 tests)
- Combined attack scenarios (3 tests)
- Response format verification (3 tests)
- Legitimate request handling (4 tests)

### Integration Tests (17 examples)
```bash
bundle exec rspec spec/requests/attack_protection_spec.rb
```

Tests cover:
- WordPress attack path protection (4 tests)
- Malicious user agent protection (3 tests)
- Legitimate request handling (3 tests)
- IP spoofing handling (2 tests)
- Middleware stack integration (2 tests)
- Attack pattern detection (3 tests)

## Monitoring

### Checking Logs for Attacks

**Production logs:**
```bash
grep "Blocked attack path" log/production.log | tail -20
grep "IP Spoofing attempt" log/production.log | tail -20
grep "Blocked malicious user agent" log/production.log | tail -20
```

**Attack statistics:**
```bash
# Count blocked paths
grep "Blocked attack path" log/production.log | wc -l

# Count IP spoofing attempts
grep "IP Spoofing attempt" log/production.log | wc -l

# Most common attack paths
grep "Blocked attack path" log/production.log | awk '{print $4}' | sort | uniq -c | sort -rn
```

### Sentry Configuration

Before this middleware, IP spoofing attacks would appear in Sentry as:
```
ActionDispatch::RemoteIp::IpSpoofAttackError
IP spoofing attack?! HTTP_CLIENT_IP="X.X.X.X" HTTP_X_FORWARDED_FOR="Y.Y.Y.Y"
```

After implementing this middleware:
- ✅ These errors are caught and logged
- ✅ They don't reach Sentry (reducing noise)
- ✅ Legitimate IP issues can still be detected if needed

## Adding New Protected Paths

To add new attack paths to the blocklist:

1. Edit `/app/middleware/attack_protection_middleware.rb`
2. Add the path to the `BLOCKED_PATHS` constant:
   ```ruby
   BLOCKED_PATHS = [
     # ... existing paths ...
     '/new-attack-path',
     '/another-path'
   ].freeze
   ```
3. Add tests in `/spec/middleware/attack_protection_middleware_spec.rb`
4. Run tests to verify: `bundle exec rspec spec/middleware/`

## Adding New Blocked User Agents

To add new malicious user agent patterns:

1. Edit `/app/middleware/attack_protection_middleware.rb`
2. Add the pattern to the `BLOCKED_USER_AGENTS` constant:
   ```ruby
   BLOCKED_USER_AGENTS = [
     # ... existing patterns ...
     /new-attack-tool/i,
     /another-scanner/i
   ].freeze
   ```
3. Add tests in `/spec/middleware/attack_protection_middleware_spec.rb`
4. Run tests to verify: `bundle exec rspec spec/middleware/`

## Performance Considerations

The middleware is designed to be extremely fast:
- Path checking uses simple string operations (`start_with?`)
- User agent checking uses regex matching only if user agent exists
- IP spoofing handling is exception-based (only triggers on actual attacks)
- No database queries or external API calls
- Minimal memory footprint (constants defined once at load time)

Impact on legitimate requests: **< 1ms overhead**

## Security Benefits

1. **Reduces server load** - Blocks attacks before they reach the application
2. **Reduces log noise** - Prevents WordPress scan attempts from filling logs
3. **Reduces Sentry noise** - IP spoofing attempts don't create error tickets
4. **Provides attack visibility** - Logs all blocked attempts for monitoring
5. **Protects against reconnaissance** - Prevents attackers from mapping the application

## Related Documentation

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [ActionDispatch::RemoteIp documentation](https://api.rubyonrails.org/classes/ActionDispatch/RemoteIp.html)

## Changelog

### 2025-10-07 - Initial Implementation
- Created `AttackProtectionMiddleware` to block WordPress/PHP attacks
- Added malicious user agent filtering
- Implemented IP spoofing protection
- Added comprehensive test coverage (57 tests total)
- All tests passing (100% success rate)
- Documented in ATTACK_PROTECTION.md

## Support

For questions or issues with the attack protection middleware:
1. Check the logs for specific error messages
2. Review the test cases for expected behavior
3. Contact the development team
