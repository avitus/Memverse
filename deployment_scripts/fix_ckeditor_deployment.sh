#!/bin/bash
# Script to fix CKEditor deployment issue with git shallow clones

echo "Fixing CKEditor deployment issue..."

# SSH into the production server and execute commands
ssh avitus@memverse.com << 'ENDSSH'
  echo "Clearing cached CKEditor git repositories..."
  
  # Remove cached git repositories
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/cache/bundler/git/ckeditor-*
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/bundler/gems/ckeditor-*
  
  # Also clear the main bundler cache for a fresh start
  rm -rf /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/cache
  
  echo "Cache cleared successfully."
  
  # Now clone the CKEditor repository manually without depth restriction
  echo "Manually cloning CKEditor repository..."
  
  mkdir -p /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/cache/bundler/git
  cd /home/avitus/memverse.com/shared/bundle/ruby/3.2.0/cache/bundler/git
  
  # Clone the repository without depth restriction
  git clone https://github.com/galetahub/ckeditor.git ckeditor-1fd593e0d9f7d7cbd0713285fc8f7edcb38af06e
  
  cd ckeditor-1fd593e0d9f7d7cbd0713285fc8f7edcb38af06e
  git checkout f6f8e2b2f61a8315ea0994db74d8e4a1ed6a2570
  
  echo "CKEditor repository cloned successfully."
ENDSSH

echo "Fix complete. You can now run 'cap production deploy' again."