namespace :sidekiq do
  desc "Generate Sidekiq systemd service file"
  task :generate_service do
    on roles(:app) do
      # Service template content
      template = <<~SERVICE
        [Unit]
        Description=Sidekiq Background Jobs for Memverse
        After=syslog.target network.target redis.service mysql.service

        [Service]
        Type=simple
        WorkingDirectory=<%= current_path %>

        # User configuration
        User=<%= fetch(:sidekiq_user, fetch(:user, 'avitus')) %>
        Group=<%= fetch(:sidekiq_user, fetch(:user, 'avitus')) %>

        # Environment setup
        Environment="RAILS_ENV=production"
        Environment="BUNDLE_PATH=<%= shared_path.join('bundle') %>"

        # Start command with log file output
        ExecStart=/bin/bash -lc 'cd <%= current_path %> && bundle exec sidekiq -e production -C config/sidekiq.yml -L <%= shared_path.join('log', 'sidekiq.log') %>'

        # Restart policy
        Restart=on-failure
        RestartSec=30
        RestartForceExitStatus=1

        # Resource limits
        LimitNOFILE=65536
        TimeoutStopSec=90

        # Process management
        KillMode=mixed
        KillSignal=SIGTERM

        [Install]
        WantedBy=multi-user.target
      SERVICE
      
      # Evaluate ERB template with Capistrano variables
      require 'erb'
      service_content = ERB.new(template).result(binding)
      
      # Write service file to shared directory
      upload! StringIO.new(service_content), "#{shared_path}/sidekiq.service"
      
      info "Sidekiq service file generated at: #{shared_path}/sidekiq.service"
      info "To install, SSH to server and run:"
      info "  sudo cp #{shared_path}/sidekiq.service /etc/systemd/system/sidekiq.service"
      info "  sudo systemctl daemon-reload"
      info "  sudo systemctl restart sidekiq"
    end
  end
  
  desc "Start Sidekiq"
  task :start do
    on roles(:app) do
      execute :sudo, "systemctl start sidekiq"
    end
  end
  
  desc "Stop Sidekiq"
  task :stop do
    on roles(:app) do
      execute :sudo, "systemctl stop sidekiq"
    end
  end
  
  desc "Restart Sidekiq"
  task :restart do
    on roles(:app) do
      execute :sudo, "systemctl restart sidekiq"
    end
  end
  
  desc "Check Sidekiq status"
  task :status do
    on roles(:app) do
      execute :sudo, "systemctl status sidekiq"
    end
  end
  
  desc "Tail Sidekiq logs"
  task :logs do
    on roles(:app) do
      execute :tail, "-f #{shared_path.join('log', 'sidekiq.log')}"
    end
  end
end

# Manual service setup - run with: cap production sidekiq:setup_service
# Commented out automatic hooks to avoid sudo issues during deployment
# after 'deploy:published', 'sidekiq:setup_service'
# after 'sidekiq:setup_service', 'sidekiq:restart'