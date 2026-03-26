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
              # Use unique markers and begin/rescue to handle warnings and decryption errors
              credential_test = capture(:bundle, :exec, :rails, :runner,
                '"begin; puts(Rails.application.credentials.present? ? \"CRED_CHECK_OK\" : \"CRED_CHECK_FAIL\"); rescue => e; puts \"CRED_CHECK_ERROR: #{e.message}\"; end"',
                raise_on_non_zero_exit: false)

              if credential_test.include?("CRED_CHECK_OK")
                info "✓ Rails credentials successfully decrypted"

                # Check if database credentials exist
                db_check = capture(:bundle, :exec, :rails, :runner,
                  '"begin; puts(Rails.application.credentials.dig(:database, :password).present? ? \"DB_CRED_OK\" : \"DB_CRED_MISSING\"); rescue => e; puts \"DB_CRED_ERROR: #{e.message}\"; end"',
                  raise_on_non_zero_exit: false)

                if db_check.include?("DB_CRED_OK")
                  info "✓ Database credentials are configured"
                else
                  warn "⚠ Database password not found in credentials"
                  warn "Add it with: EDITOR=\"nano\" rails credentials:edit"
                  warn "Under database: password: your_password"
                end
              else
                error "✗ Failed to decrypt Rails credentials"
                error "Output: #{credential_test.strip}"
                error "Ensure master.key matches credentials.yml.enc"
                error "Re-copy with: scp config/master.key #{fetch(:user)}@www.memverse.com:#{master_key_path}"
              end
            end
          end
        else
          error "✗ No master.key found at #{master_key_path}"
          error "Copy it from your local machine:"
          error "scp config/master.key #{fetch(:user)}@www.memverse.com:#{master_key_path}"
        end
      end
    end
  end

  # Run this check before migrations
  before 'deploy:migrate', 'deploy:check:credentials'
end
