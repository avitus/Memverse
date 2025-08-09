# Fix for Capistrano to use Ruby 3.2.6

# Add these lines to your config/deploy.rb or config/deploy/production.rb

# Option 1: Add to config/deploy/production.rb (Recommended)
# This tells Capistrano to use Ruby 3.2.6 for the rails-7-upgrade deployment

set :rvm_ruby_version, '3.2.6'

# Option 2: If that doesn't work, force RVM to use 3.2.6
# Add this to config/deploy.rb after other set statements:

set :rvm_type, :user
set :rvm_ruby_version, '3.2.6'
set :rvm_custom_path, '/home/avitus/.rvm'

# Make sure RVM bin is in the path
set :rvm_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl}

# Option 3: Create a .ruby-version file in the deployment directory
# SSH to server and run:
# echo "3.2.6" > /home/avitus/memverse.com/current/.ruby-version
# echo "3.2.6" > /home/avitus/memverse.com/.ruby-version