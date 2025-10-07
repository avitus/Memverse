# frozen_string_literal: true

# Require the middleware file explicitly to ensure it's loaded before configuration
require Rails.root.join('app/middleware/attack_protection_middleware')

# Add attack protection middleware early in the stack
# This must run before ActionDispatch::RemoteIp to catch IP spoofing attempts
Rails.application.config.middleware.insert_before ActionDispatch::RemoteIp, AttackProtectionMiddleware
