namespace :deploy do
  namespace :check do
    desc "Check database configuration"
    task :database_config do
      on roles(:app) do
        info "Checking database configuration..."
        
        # Check if database.yml exists in shared path
        database_yml_path = shared_path.join('config/database.yml')
        if test("[ -f #{database_yml_path} ]")
          info "✓ Found database.yml at #{database_yml_path}"
          
          # Extract production database username (without showing password)
          within release_path do
            production_config = capture(:cat, database_yml_path)
            if production_config.include?("production:")
              info "✓ Production configuration found in database.yml"
              
              # Extract username safely
              username_match = production_config.match(/production:.*?username:\s*(\w+)/m)
              if username_match
                username = username_match[1]
                info "Database username: #{username}"
                
                if username == "root"
                  error "WARNING: Using 'root' as database username in production!"
                  error "This might be causing the connection issue."
                end
              else
                error "Could not extract username from database.yml"
              end
            else
              error "No production configuration found in database.yml!"
            end
          end
          
          # Check if the symlink is correct
          linked_database_yml = release_path.join('config/database.yml')
          if test("[ -L #{linked_database_yml} ]")
            actual_target = capture(:readlink, linked_database_yml)
            info "database.yml is symlinked to: #{actual_target}"
          else
            error "database.yml is not properly symlinked!"
          end
          
        else
          error "✗ No database.yml found at #{database_yml_path}"
          error "You need to create this file on the server with proper credentials"
        end
        
        # Also check master.key for credentials
        master_key_path = shared_path.join('config/master.key')
        if test("[ -f #{master_key_path} ]")
          info "✓ Found master.key for Rails credentials"
        else
          warn "No master.key found - Rails credentials might not work"
        end
      end
    end
  end
  
  # Run this check before migrations
  before 'deploy:migrate', 'deploy:check:database_config'
end