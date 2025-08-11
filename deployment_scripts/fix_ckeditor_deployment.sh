#!/bin/bash
# Script to fix git-based gems deployment issue with shallow clones

echo "Fixing git-based gems deployment issue..."

# SSH into the production server and execute commands
ssh avitus@memverse.com << 'ENDSSH'
  echo "Clearing all cached git gem repositories..."
  
  # Clear entire bundler git cache to force fresh clones
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/cache/bundler/git/*
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/bundler/gems/*
  
  # Also clear the gems cache
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/cache/*.gem
  
  echo "Cache cleared successfully."
  echo "Next deployment will fetch fresh copies of all gems."
ENDSSH

echo "Fix complete. You can now run 'cap production deploy' again."