# Fixing RVM with Capistrano

## The Problem
RVM is installed but Capistrano can't find it because RVM requires sourcing scripts that aren't loaded in non-interactive shells.

## Solution 1: Update deploy.rb (Recommended)

Add these lines to your `config/deploy.rb`:

```ruby
# RVM configuration
set :rvm_type, :user
set :rvm_ruby_version, '2.7.8'  # Current version, will change to 3.2.6 later
set :rvm_custom_path, '/home/avitus/.rvm'  # Adjust if RVM is elsewhere

# Ensure RVM is loaded for all commands
set :default_env, {
  'PATH' => '/home/avitus/.rvm/gems/ruby-2.7.8/bin:/home/avitus/.rvm/gems/ruby-2.7.8@global/bin:/home/avitus/.rvm/rubies/ruby-2.7.8/bin:/home/avitus/.rvm/bin:$PATH',
  'GEM_HOME' => '/home/avitus/.rvm/gems/ruby-2.7.8',
  'GEM_PATH' => '/home/avitus/.rvm/gems/ruby-2.7.8:/home/avitus/.rvm/gems/ruby-2.7.8@global',
  'RUBY_VERSION' => 'ruby-2.7.8'
}
```

## Solution 2: Install Ruby Manually via SSH

Since RVM is already installed, you can install Ruby 3.2.6 directly:

```bash
# SSH to production
ssh avitus@www.memverse.com

# Load RVM
source ~/.rvm/scripts/rvm

# Install Ruby 3.2.6
rvm install 3.2.6

# Install bundler for the new Ruby
rvm use 3.2.6
gem install bundler

# Verify installation
ruby -v
# Should show: ruby 3.2.6...

# Exit SSH
exit
```

## Solution 3: Fix Capistrano Task

Update the `rails7:install_ruby` task in `lib/capistrano/tasks/rails7_upgrade.rake`:

```ruby
desc "Install Ruby 3.2.6 using RVM"
task :install_ruby do
  on roles(:app) do
    info "Installing Ruby 3.2.6..."
    
    # Source RVM and run commands
    execute :bash, '-l -c "source ~/.rvm/scripts/rvm && rvm install 3.2.6"'
    execute :bash, '-l -c "source ~/.rvm/scripts/rvm && rvm use 3.2.6 && gem install bundler"'
    
    info "✓ Ruby 3.2.6 installed successfully"
  end
end
```

## Solution 4: Use capistrano-rvm Gem

Add to your Gemfile:

```ruby
gem 'capistrano-rvm', group: :development
```

Then in your Capfile:

```ruby
require 'capistrano/rvm'
```

This gem handles RVM loading automatically.

## Recommended Approach

For immediate deployment, use **Solution 2** (manual SSH installation) since:
1. It's quickest
2. You can verify each step
3. No code changes needed
4. RVM is already working on the server

After Ruby 3.2.6 is installed, the deployment will work fine.