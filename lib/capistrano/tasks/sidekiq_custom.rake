# Custom Capistrano tasks for Sidekiq with scheduler/worker architecture
# This manages Sidekiq using systemctl --user commands (no sudo required)

namespace :sidekiq do
  desc "Quiet Sidekiq (stop accepting new jobs)"
  task :quiet do
    on roles(:app) do
      info "Putting Sidekiq into quiet mode..."
      # Use systemctl --user to send TSTP signal (quiet mode)
      execute "systemctl --user kill -s TSTP sidekiq-scheduler || true"
      execute "systemctl --user kill -s TSTP 'sidekiq-workers@*' || true"
      info "Sidekiq is now in quiet mode (finishing current jobs)"
    end
  end
  
  desc "Stop Sidekiq scheduler and workers"
  task :stop do
    on roles(:app) do
      info "Stopping Sidekiq services..."
      execute "systemctl --user stop sidekiq-scheduler || true"
      execute "systemctl --user stop 'sidekiq-workers@*' || true"
      info "Sidekiq services stopped"
    end
  end
  
  desc "Start Sidekiq scheduler and workers"  
  task :start do
    on roles(:app) do
      info "Starting Sidekiq services..."
      execute "systemctl --user start sidekiq-scheduler"
      
      # Start the configured number of workers
      worker_count = fetch(:sidekiq_workers, 3)
      (1..worker_count).each do |i|
        execute "systemctl --user start sidekiq-workers@#{i}"
      end
      
      info "Started scheduler + #{worker_count} workers"
    end
  end
  
  desc "Restart Sidekiq services"
  task :restart do
    invoke 'sidekiq:quiet'
    sleep 10  # Give jobs time to finish
    invoke 'sidekiq:stop'
    invoke 'sidekiq:start'
  end
  
  desc "Rolling restart (zero downtime)"
  task :rolling_restart do
    on roles(:app) do
      info "Performing rolling restart..."
      
      worker_count = fetch(:sidekiq_workers, 3)
      
      # Restart workers one by one
      (1..worker_count).each do |i|
        info "Restarting worker #{i}..."
        execute "systemctl --user restart sidekiq-workers@#{i}"
        sleep 2
      end
      
      # Finally restart scheduler
      info "Restarting scheduler..."
      execute "systemctl --user restart sidekiq-scheduler"
      
      info "Rolling restart complete"
    end
  end
  
  desc "Check Sidekiq status"
  task :status do
    on roles(:app) do
      info "Sidekiq services status:"
      execute "systemctl --user status sidekiq-scheduler --no-pager || true"
      execute "systemctl --user status 'sidekiq-workers@*' --no-pager || true"
    end
  end
end

# Hook into Capistrano deployment
namespace :deploy do
  # Quiet sidekiq before deploying new code
  after 'deploy:starting', 'sidekiq:quiet'
  
  # Restart sidekiq after new code is deployed
  after 'deploy:published', 'sidekiq:restart'
  
  # Check status after deployment
  after 'deploy:finished', 'sidekiq:status'
end

# Allow overriding the deployment strategy via environment variable
if ENV['SIDEKIQ_DEPLOY_STRATEGY'] == 'rolling'
  Rake::Task['deploy:published'].prerequisites.delete('sidekiq:restart')
  
  namespace :deploy do
    after 'deploy:published', 'sidekiq:rolling_restart'
  end
end