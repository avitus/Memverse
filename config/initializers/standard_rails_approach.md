# Standard Rails Approaches for IP Spoofing

## Option 1: Disable IP Spoofing Check (Not Recommended)
```ruby
# config/environments/production.rb
config.action_dispatch.ip_spoofing_check = false
```

## Option 2: Remove Conflicting Headers (Recommended)
```ruby
# config/application.rb
config.middleware.insert_before ActionDispatch::RemoteIp, Rack::Config do |env|
  env.delete 'HTTP_CLIENT_IP'
end
```

## Option 3: Simple Error Handler (Most Standard)
```ruby
# config/application.rb
require_relative '../app/middleware/ip_spoof_handler'
config.middleware.insert_before ActionDispatch::RemoteIp, IpSpoofHandler
```

## Option 4: Configure Trusted Proxies
```ruby
# config/application.rb
# For AWS ELB or known proxy IPs
config.action_dispatch.trusted_proxies = /^10\.|^172\.(1[6-9]|2[0-9]|3[01])\.|^192\.168\./
```

## Current Implementation
We've implemented a comprehensive `AttackProtectionMiddleware` that goes beyond standard Rails practices by also blocking WordPress attack paths. This is more than typically needed but provides additional security.