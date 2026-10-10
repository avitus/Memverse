set :rails_env, "production" 

# Server configuration
# martial-eagle (DigitalOcean sfo3, Ubuntu 24.04). Addressed by IP on purpose: www.memverse.com
# pointed at fish-eagle until the 2026-10 migration and must never decide where a deploy lands.
# The legacy host is reachable as the `fish_eagle` stage until it is decommissioned.
# See documentation/plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md
server '64.23.176.115', user: 'avitus', roles: %w{app db web}

# Deploy from rails-7-upgrade branch
set :branch, 'main'

# Ruby version
set :rvm_ruby_version, '3.2.6'

# Credentials via master.key + credentials.yml.enc (contains secret_key_base, DB password, Postmark token)
set :linked_files, fetch(:linked_files, []).push(
  'config/master.key'
)

# Additional linked directories for Rails 7
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'public/assets',      # Shared compiled assets
  'public/ckeditor_assets',
  'public/uploads',     # Paperclip legacy
  'storage'            # Active Storage
)

# Rails 7 specific settings
set :keep_assets, 2  # Keep fewer assets to save space

# Puma configuration (if using Puma)
set :puma_threads, [4, 16]
set :puma_workers, 2
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{shared_path}/log/puma_access.log"
set :puma_error_log, "#{shared_path}/log/puma_error.log"

# Sidekiq configuration - Using custom multi-process setup
# We use systemd services instead of capistrano-sidekiq's default behavior
# See lib/capistrano/tasks/sidekiq_multi.rake for custom tasks
set :sidekiq_default_hooks, false  # Disable default capistrano-sidekiq hooks
set :sidekiq_workers, ENV.fetch('SIDEKIQ_WORKERS', 2)  # Number of worker processes (2 on martial-eagle, shared with other apps)

# SSH options
set :ssh_options, {
  keys: [File.join(ENV.fetch("HOME"), ".ssh", "id_ed25519")],
  forward_agent: true,
  auth_methods: %w(publickey)
}

# Ensure correct Node.js version is used
set :default_env, { 
  path: "/home/avitus/.nvm/versions/node/v24.21.0/bin:$PATH",
  NODE_ENV: 'production'
}

# RVM configuration for Rails 7
set :rvm_type, :user
set :rvm_custom_path, '/home/avitus/.rvm'
set :rvm_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl}

# Deployment hooks specific to Rails 7
namespace :deploy do
  # Override compile assets to handle Rails 7 specifics
  namespace :assets do
    desc 'Precompile assets with Rails 7 optimizations'
    task :precompile do
      on roles(:web) do
        within release_path do
          with rails_env: fetch(:rails_env), rails_groups: fetch(:rails_assets_groups) do
            # Clear ALL assets first (clobber removes everything, not just old ones)
            execute :bundle, "exec rails assets:clobber"
            
            # Compile new assets
            execute :bundle, "exec rails assets:precompile"
          end
        end
      end
    end
  end

  # Custom restart for Rails 7
  desc 'Restart application with Rails 7 considerations'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Touch restart file for Passenger
      execute :touch, release_path.join('tmp/restart.txt')
      
      # If using Puma
      # invoke 'puma:restart'
    end
  end

  # Rails 7 specific checks
  before :starting, :check_rails_7 do
    on roles(:app) do
      # Verify Ruby 3.2.6 using RVM
      within fetch(:rvm_custom_path, '/home/avitus/.rvm') do
        ruby_version = capture("#{fetch(:rvm_custom_path, '/home/avitus/.rvm')}/bin/rvm current")
        info "Current RVM Ruby: #{ruby_version}"
        
        unless ruby_version.include?("ruby-3.2.6")
          error "Ruby 3.2.6 required but not found!"
          error "Current Ruby: #{ruby_version}"
          raise "Ruby 3.2.6 required on #{host} but RVM reports #{ruby_version.strip}; run: rvm use 3.2.6 --default"
        end
      end
    end
  end

  # Clear cache after deployment
  after :published, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        execute :bundle, "exec rails r 'Rails.cache.clear' RAILS_ENV=production"
      end
    end
  end

  # NOTE: Whenever gem is not used in this project
  # Cron jobs are managed by Sidekiq's cron scheduling instead
end

# Rails 7 specific tasks
after 'deploy:publishing', 'deploy:restart'
after 'deploy:finishing', 'thinking_sphinx:index'
after 'deploy:finishing', 'thinking_sphinx:restart'
after 'deploy:finishing', 'deploy:cleanup'

# NOTE: Maintenance mode is not needed for regular deployments
# Capistrano handles zero-downtime deployments by default