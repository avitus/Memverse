# Custom Capistrano tasks for managing Sidekiq scheduler and workers
# This replaces the default capistrano-sidekiq behavior to support our architecture:
# - 1 scheduler process (loads cron jobs)
# - Multiple worker processes (job execution only)

namespace :sidekiq do
  namespace :multi do
    desc "Setup Sidekiq with scheduler and workers architecture"
    task :setup do
      on roles(:app) do
        info "Setting up Sidekiq multi-process architecture..."
        
        # Create systemd service files from templates
        upload! "deployment_scripts/sidekiq-scheduler.service", "/tmp/sidekiq-scheduler.service"
        upload! "deployment_scripts/sidekiq-workers@.service", "/tmp/sidekiq-workers@.service"
        
        # Install service files
        execute :sudo, "mv /tmp/sidekiq-scheduler.service /etc/systemd/system/"
        execute :sudo, "mv /tmp/sidekiq-workers@.service /etc/systemd/system/"
        execute :sudo, "systemctl daemon-reload"
        
        info "Sidekiq systemd services installed"
      end
    end
    
    desc "Start Sidekiq scheduler and workers"
    task :start do
      on roles(:app) do
        within current_path do
          info "Starting Sidekiq scheduler..."
          execute :sudo, "systemctl start sidekiq-scheduler"
          
          # Start worker processes (configurable via ENV or default to 3)
          worker_count = ENV.fetch('SIDEKIQ_WORKERS', '3').to_i
          info "Starting #{worker_count} Sidekiq workers..."
          
          worker_count.times do |i|
            execute :sudo, "systemctl start sidekiq-workers@#{i + 1}"
          end
          
          info "Sidekiq services started"
        end
      end
    end
    
    desc "Stop Sidekiq scheduler and workers"
    task :stop do
      on roles(:app) do
        info "Stopping Sidekiq services..."
        execute :sudo, "systemctl stop sidekiq-scheduler", raise_on_non_zero_exit: false
        execute :sudo, "systemctl stop 'sidekiq-workers@*'", raise_on_non_zero_exit: false
        info "Sidekiq services stopped"
      end
    end
    
    desc "Restart Sidekiq scheduler and workers (with quiet period)"
    task :restart do
      on roles(:app) do
        info "Restarting Sidekiq services with quiet period..."
        
        # Send TSTP (quiet) signal first to stop accepting new jobs
        execute :sudo, "systemctl kill -s TSTP sidekiq-scheduler", raise_on_non_zero_exit: false
        execute :sudo, "systemctl kill -s TSTP 'sidekiq-workers@*'", raise_on_non_zero_exit: false
        
        info "Waiting for jobs to finish (quiet mode)..."
        sleep 10
        
        # Now restart the services
        execute :sudo, "systemctl restart sidekiq-scheduler"
        
        worker_count = ENV.fetch('SIDEKIQ_WORKERS', '3').to_i
        worker_count.times do |i|
          execute :sudo, "systemctl restart sidekiq-workers@#{i + 1}"
        end
        
        info "Sidekiq services restarted"
      end
    end
    
    desc "Check status of Sidekiq services"
    task :status do
      on roles(:app) do
        info "Checking Sidekiq services status..."
        execute :sudo, "systemctl status sidekiq-scheduler --no-pager", raise_on_non_zero_exit: false
        execute :sudo, "systemctl status 'sidekiq-workers@*' --no-pager", raise_on_non_zero_exit: false
      end
    end
    
    desc "Enable Sidekiq services to start on boot"
    task :enable do
      on roles(:app) do
        info "Enabling Sidekiq services..."
        execute :sudo, "systemctl enable sidekiq-scheduler"
        
        worker_count = ENV.fetch('SIDEKIQ_WORKERS', '3').to_i
        worker_count.times do |i|
          execute :sudo, "systemctl enable sidekiq-workers@#{i + 1}"
        end
        
        info "Sidekiq services enabled for auto-start"
      end
    end
    
    desc "Disable Sidekiq services from starting on boot"
    task :disable do
      on roles(:app) do
        info "Disabling Sidekiq services..."
        execute :sudo, "systemctl disable sidekiq-scheduler", raise_on_non_zero_exit: false
        execute :sudo, "systemctl disable 'sidekiq-workers@*'", raise_on_non_zero_exit: false
        info "Sidekiq services disabled"
      end
    end
    
    desc "Rolling restart of Sidekiq workers (zero downtime)"
    task :rolling_restart do
      on roles(:app) do
        info "Performing rolling restart of Sidekiq workers..."
        
        worker_count = ENV.fetch('SIDEKIQ_WORKERS', '3').to_i
        
        # Restart workers one by one
        worker_count.times do |i|
          worker_num = i + 1
          info "Restarting worker #{worker_num}..."
          
          # Send quiet signal
          execute :sudo, "systemctl kill -s TSTP sidekiq-workers@#{worker_num}", raise_on_non_zero_exit: false
          sleep 5
          
          # Restart the worker
          execute :sudo, "systemctl restart sidekiq-workers@#{worker_num}"
          
          # Wait for it to be ready before moving to next
          sleep 3
        end
        
        # Finally restart the scheduler
        info "Restarting scheduler..."
        execute :sudo, "systemctl restart sidekiq-scheduler"
        
        info "Rolling restart complete"
      end
    end
    
    desc "View Sidekiq logs"
    task :logs do
      on roles(:app) do
        # Show last 50 lines of logs
        info "=== Scheduler logs ==="
        execute :sudo, "journalctl -u sidekiq-scheduler -n 50 --no-pager"
        
        info "\n=== Worker 1 logs ==="
        execute :sudo, "journalctl -u sidekiq-workers@1 -n 50 --no-pager"
      end
    end
  end
  
  # Override default sidekiq tasks to use our multi-process setup
  desc "Start Sidekiq (multi-process)"
  task :start do
    invoke 'sidekiq:multi:start'
  end
  
  desc "Stop Sidekiq (multi-process)"
  task :stop do
    invoke 'sidekiq:multi:stop'
  end
  
  desc "Restart Sidekiq (multi-process)"
  task :restart do
    invoke 'sidekiq:multi:restart'
  end
  
  desc "Rolling restart Sidekiq (multi-process)"
  task :rolling_restart do
    invoke 'sidekiq:multi:rolling_restart'
  end
end

# Hook into Capistrano deployment lifecycle
namespace :deploy do
  # Stop Sidekiq before deployment starts
  before :starting, :stop_sidekiq do
    invoke 'sidekiq:multi:stop'
  end
  
  # Start Sidekiq after deployment is published
  after :published, :start_sidekiq do
    invoke 'sidekiq:multi:start'
  end
  
  # Alternative: Use rolling restart for zero-downtime deployments
  # Uncomment these and comment out the above if you prefer rolling restarts
  # after :updated, :sidekiq_quiet do
  #   on roles(:app) do
  #     info "Putting Sidekiq in quiet mode..."
  #     execute :sudo, "systemctl kill -s TSTP sidekiq-scheduler", raise_on_non_zero_exit: false
  #     execute :sudo, "systemctl kill -s TSTP 'sidekiq-workers@*'", raise_on_non_zero_exit: false
  #   end
  # end
  # 
  # after :published, :sidekiq_rolling_restart do
  #   invoke 'sidekiq:multi:rolling_restart'
  # end
end