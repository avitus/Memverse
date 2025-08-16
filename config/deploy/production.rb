set :rails_env, "production" 

# Server configuration
server 'www.memverse.com', user: 'avitus', roles: %w{app db web}

# Deploy from rails-7-upgrade branch
set :branch, 'main'

# Ruby version
set :rvm_ruby_version, '3.2.6'

# Additional linked files for Rails 7
set :linked_files, fetch(:linked_files, []).push(
  'config/secrets.yml.key',
  'config/master.key',  # Rails 7 credentials
  'config/database.yml' # If not in repo
)

# Additional linked directories for Rails 7
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
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

# Sidekiq configuration
set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }
set :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
set :sidekiq_pid, -> { File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') }

# SSH options
set :ssh_options, {
  keys: [File.join(ENV["HOME"], ".ssh", "id_rsa")],
  forward_agent: true,
  auth_methods: %w(publickey password)
}

# Ensure correct Node.js version is used
set :default_env, { 
  path: "/home/avitus/.nvm/versions/node/v16.20.2/bin:$PATH",
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
            # Clear old assets first
            execute :bundle, "exec rails assets:clean"
            
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
          error "Please ensure RVM is using Ruby 3.2.6 by running: rvm use 3.2.6"
          exit 1
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

  # Update crontab for whenever gem (if used)
  after :finishing, :update_cron do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec whenever --update-crontab #{fetch(:application)}"
      end
    end
  end
end

# Rails 7 specific tasks
after 'deploy:publishing', 'deploy:restart'
after 'deploy:finishing', 'thinking_sphinx:index'
after 'deploy:finishing', 'thinking_sphinx:restart'
after 'deploy:finishing', 'deploy:cleanup'

# Maintenance mode handling
before 'deploy:starting', 'rails7:enable_maintenance'
after 'deploy:finished', 'rails7:disable_maintenance'