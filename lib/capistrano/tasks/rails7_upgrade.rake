# Capistrano tasks for Rails 7 upgrade deployment
# This file contains special tasks for the major upgrade

namespace :rails7 do
  desc "Check if server is ready for Rails 7 deployment"
  task :check_prerequisites do
    on roles(:app) do
      info "Checking Rails 7 deployment prerequisites..."
      
      # Check Ruby version
      within release_path do
        ruby_version = capture(:ruby, "-v")
        info "Current Ruby: #{ruby_version}"
        
        unless ruby_version.include?("3.2.6")
          error "Ruby 3.2.6 is required but not found!"
          error "Please run: cap production rails7:install_ruby"
          exit 1
        end
      end
      
      # Check MySQL version
      mysql_version = capture(:mysql, "--version")
      info "MySQL version: #{mysql_version}"
      
      # Extract version number
      if mysql_version =~ /(\d+\.\d+\.\d+)/
        version = $1
        major_minor = version.split('.')[0..1].join('.')
        
        if mysql_version.include?("MariaDB")
          if major_minor.to_f < 10.2
            error "MariaDB 10.2+ is required for Rails 7 (found #{version})"
            exit 1
          end
        else
          if major_minor.to_f < 5.7
            error "MySQL 5.7+ is required for Rails 7 (found #{version})"
            exit 1
          end
        end
      end
      
      info "✓ All prerequisites met!"
    end
  end

  desc "Create comprehensive backup before Rails 7 deployment"
  task :backup do
    on roles(:db) do
      info "Creating backup before Rails 7 deployment..."
      
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      backup_dir = "/var/backups/memverse/rails7_upgrade_#{timestamp}"
      
      execute :mkdir, "-p", backup_dir
      
      # Backup database
      info "Backing up database..."
      info "Note: For a verified backup with password handling, use deployment_scripts/verified_backup.sh"
      
      # Create a simple backup without PROCESS privilege requirements
      within backup_dir do
        # This is a basic backup - for production use verified_backup.sh
        execute :mysqldump, 
          "-u", fetch(:database_username, "memverse"),
          "-p",  # Will prompt for password
          "--single-transaction",
          "--no-tablespaces",  # Avoid PROCESS privilege requirement
          fetch(:database_name, "memverse_production"),
          "> database_full.sql"
        
        execute :gzip, "database_full.sql"
      end
      
      # Backup current code
      info "Backing up current code..."
      within backup_dir do
        execute :tar, "-czf", "code_backup.tar.gz", "-C", deploy_to, "current"
      end
      
      # Backup uploads (Paperclip files)
      if test("[ -d #{shared_path}/public/uploads ]")
        info "Backing up uploaded files..."
        within backup_dir do
          execute :tar, "-czf", "uploads_backup.tar.gz", "-C", "#{shared_path}/public", "uploads"
        end
      end
      
      # Record current state
      within backup_dir do
        execute :echo, "\"Backup created: #{timestamp}\" > backup_info.txt"
        execute :echo, "\"Previous branch: #{fetch(:branch)}\" >> backup_info.txt"
        execute :echo, "\"Previous commit: $(cd #{current_path} && git rev-parse HEAD)\" >> backup_info.txt"
      end
      
      info "✓ Backup completed: #{backup_dir}"
      set :rails7_backup_dir, backup_dir
    end
  end

  desc "Install Ruby 3.2.6 using RVM"
  task :install_ruby do
    on roles(:app) do
      info "Installing Ruby 3.2.6..."
      
      # Check if RVM is installed
      if test("command -v rvm")
        execute :rvm, "get stable"
        execute :rvm, "install 3.2.6"
        execute :rvm, "use 3.2.6 --default"
        
        # Install bundler
        execute :gem, "install bundler"
        
        info "✓ Ruby 3.2.6 installed successfully"
      else
        error "RVM not found. Please install RVM first."
        exit 1
      end
    end
  end

  desc "Enable maintenance mode (only for major upgrades that require downtime)"
  task :enable_maintenance do
    on roles(:web) do
      info "Enabling maintenance mode..."
      
      maintenance_file = "#{shared_path}/public/maintenance.html"
      
      # Create maintenance page
      execute :echo, %q{'<!DOCTYPE html>
<html>
<head>
  <title>Memverse - Maintenance in Progress</title>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
    .container { max-width: 600px; margin: 0 auto; }
    h1 { color: #333; }
    .message { background: #f8f8f8; padding: 20px; border-radius: 5px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Memverse is Currently Under Maintenance</h1>
    <div class="message">
      <p>We are upgrading our system to provide you with better performance and new features.</p>
      <p><strong>Estimated completion: 30-45 minutes</strong></p>
      <p>Your verses and progress are safe!</p>
    </div>
  </div>
</body>
</html>'} > maintenance_file
      
      # Symlink to enable
      execute :ln, "-sf", maintenance_file, "#{current_path}/public/maintenance.html"
      
      info "✓ Maintenance mode enabled"
    end
  end

  desc "Disable maintenance mode"
  task :disable_maintenance do
    on roles(:web) do
      info "Disabling maintenance mode..."
      execute :rm, "-f", "#{current_path}/public/maintenance.html"
      info "✓ Maintenance mode disabled"
    end
  end

  desc "Run post-deployment verification"
  task :verify do
    on roles(:app) do
      info "Running post-deployment verification..."
      
      within current_path do
        # Check Rails version
        rails_version = capture(:bundle, "exec rails -v")
        info "Rails version: #{rails_version}"
        
        unless rails_version.include?("7.0")
          error "Rails 7.0 not detected!"
        end
        
        # Check migrations
        info "Checking migration status..."
        execute :bundle, "exec rails db:migrate:status RAILS_ENV=production"
        
        # Check if Active Storage tables exist
        info "Verifying Active Storage..."
        execute :bundle, "exec rails runner 'puts ActiveStorage::Blob.table_exists?' RAILS_ENV=production"
        
        # Quick health check
        info "Testing application response..."
        response = capture("curl -s -o /dev/null -w '%{http_code}' http://localhost/ || echo 'FAIL'")
        
        if response == "200"
          info "✓ Application responding correctly"
        else
          error "Application not responding! HTTP status: #{response}"
        end
      end
    end
  end

  desc "Emergency rollback to previous version"
  task :rollback_emergency do
    on roles(:app) do
      error "Starting emergency rollback..."
      
      # Get backup directory
      backup_dir = fetch(:rails7_backup_dir)
      
      if backup_dir.nil?
        error "No backup directory set. Manual rollback required!"
        exit 1
      end
      
      # Stop services
      invoke 'sidekiq:stop'
      # Add your web server stop command here
      
      # Restore code
      within deploy_to do
        execute :rm, "-rf current"
        execute :tar, "-xzf", "#{backup_dir}/code_backup.tar.gz"
      end
      
      # Restore database
      info "Restoring database from backup..."
      execute "gunzip < #{backup_dir}/database_full.sql.gz | mysql -u root -p"
      
      # Restart services
      # Add your web server start command here
      invoke 'sidekiq:start'
      
      info "✓ Emergency rollback completed"
    end
  end

  desc "Complete Rails 7 deployment process"
  task :deploy do
    # This is the main task that orchestrates the Rails 7 deployment
    
    invoke 'rails7:check_prerequisites'
    invoke 'rails7:backup'
    invoke 'rails7:enable_maintenance'
    
    # Set branch to rails-7-upgrade for this deployment
    set :branch, 'rails-7-upgrade'
    
    # Run standard deployment
    invoke 'deploy'
    
    # Rails 7 specific post-deployment tasks
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          # Clear cache
          info "Clearing Rails cache..."
          execute :bundle, "exec rails r 'Rails.cache.clear'"
          
          # Ensure Active Storage is properly set up
          info "Setting up Active Storage..."
          execute :bundle, "exec rails active_storage:install RAILS_ENV=production"
        end
      end
    end
    
    invoke 'rails7:disable_maintenance'
    invoke 'rails7:verify'
    
    info "Rails 7 deployment completed successfully!"
  end
end

# Override the standard deploy:migrate task to handle Rails 7 specifics
namespace :deploy do
  task :migrate do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Running Rails 7 migrations..."
          
          # Show pending migrations
          pending = capture(:bundle, "exec rails db:migrate:status | grep 'down' | wc -l").to_i
          
          if pending > 0
            info "Found #{pending} pending migrations"
            
            # Run migrations
            execute :bundle, "exec rails db:migrate"
            
            # Special handling for Active Storage migration
            if capture(:bundle, "exec rails db:migrate:status | grep 'create_active_storage'").include?("up")
              info "Active Storage tables created successfully"
            end
          else
            info "No pending migrations"
          end
        end
      end
    end
  end
end