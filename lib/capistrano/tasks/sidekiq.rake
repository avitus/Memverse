namespace :sidekiq do
  desc "Setup Sidekiq systemd service"
  task :setup_service do
    on roles(:app) do
      template = File.read(File.expand_path("../../../config/deploy/templates/sidekiq.service.erb", __FILE__))
      
      # Evaluate ERB template with Capistrano variables
      require 'erb'
      service_content = ERB.new(template).result(binding)
      
      # Write service file
      upload! StringIO.new(service_content), "/tmp/sidekiq.service"
      
      # Install service file
      execute :sudo, "mv /tmp/sidekiq.service /etc/systemd/system/sidekiq.service"
      execute :sudo, "systemctl daemon-reload"
      
      info "Sidekiq service file updated. Logs will be written to #{shared_path.join('log', 'sidekiq.log')}"
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

# Hook into Capistrano deployment
after 'deploy:published', 'sidekiq:setup_service'
after 'sidekiq:setup_service', 'sidekiq:restart'