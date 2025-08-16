namespace :deploy do
  namespace :check do
    desc "Check Rails credentials configuration"
    task :credentials do
      on roles(:app) do
        info "Checking Rails credentials configuration..."
        
        # Check if master.key exists in shared path
        master_key_path = shared_path.join('config/master.key')
        if test("[ -f #{master_key_path} ]")
          info "✓ Found master.key at #{master_key_path}"
          
          # Verify credentials can be decrypted
          within release_path do
            with rails_env: fetch(:rails_env) do
              # Test if credentials can be read
              credential_test = capture(:bundle, :exec, :rails, :runner, 
                '"puts Rails.application.credentials.present? ? :success : :failed"')
              
              if credential_test.strip == "success"
                info "✓ Rails credentials successfully decrypted"
                
                # Check if database credentials exist
                db_check = capture(:bundle, :exec, :rails, :runner,
                  '"puts Rails.application.credentials.dig(:database, :password).present? ? :configured : :missing"')
                
                if db_check.strip == "configured"
                  info "✓ Database credentials are configured"
                else
                  warn "⚠ Database password not found in credentials"
                  warn "Add it with: rails credentials:edit"
                  warn "Under database: password: your_password"
                end
              else
                error "✗ Failed to decrypt Rails credentials"
                error "Ensure master.key is correct"
              end
            end
          end
        else
          error "✗ No master.key found at #{master_key_path}"
          error "Copy it from your local machine:"
          error "scp config/master.key #{fetch(:user)}@#{fetch(:server)}:#{master_key_path}"
        end
      end
    end
  end
  
  # Run this check before migrations
  before 'deploy:migrate', 'deploy:check:credentials'
end