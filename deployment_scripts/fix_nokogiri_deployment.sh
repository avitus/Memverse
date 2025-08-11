#!/bin/bash
# Script to fix Nokogiri glibc compatibility issue

echo "Fixing Nokogiri platform issue on production server..."

# SSH into the production server and execute commands
ssh avitus@memverse.com << 'ENDSSH'
  echo "Setting bundler to use ruby platform for Nokogiri..."
  
  # Navigate to the app directory
  cd /home/avitus/memverse.com/current
  
  # Set bundler config to force ruby platform (compile from source)
  bundle config set --local force_ruby_platform true
  
  # Remove the existing precompiled Nokogiri gem
  echo "Removing precompiled Nokogiri gem..."
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/gems/nokogiri-*
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/specifications/nokogiri-*
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/extensions/*/3.2.0/nokogiri-*
  
  # Install build dependencies if needed
  echo "Checking for build dependencies..."
  which gcc > /dev/null 2>&1 || echo "WARNING: gcc not found. You may need to install build-essential"
  
  # Reinstall Nokogiri from source
  echo "Installing Nokogiri from source (this may take a few minutes)..."
  cd /home/avitus/memverse.com/current
  bundle install --path /home/avitus/memverse.com/shared/bundle --deployment --without development test
  
  echo "Nokogiri installation complete."
ENDSSH

echo "Fix complete. You can now run 'cap production deploy' again."