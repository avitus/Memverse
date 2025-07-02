namespace :bundler do
  desc "Ensure server environment is properly set up for deployment"
  task :setup_environment do
    on roles(:app) do
      within release_path do
        puts "=== Setting up deployment environment ==="
        
        # Ensure we're using the correct Ruby version
        puts "Checking Ruby version..."
        execute :ruby, "--version"
        
        # Check if bundler is available and at the correct version
        puts "Checking bundler availability..."
        begin
          execute :bundle, "--version"
        rescue SSHKit::Command::Failed
          puts "Bundler not found, installing compatible version..."
          execute :gem, "install bundler -v 2.1.4"
        end
        
        # For major upgrades, clean the bundle to ensure fresh installation
        puts "Checking if this is a major upgrade..."
        begin
          execute :test, "-d #{shared_path}/bundle"
          puts "Existing bundle found, cleaning for fresh installation..."
          execute :rm, "-rf #{shared_path}/bundle"
          puts "Cleaned existing bundle for fresh installation"
        rescue SSHKit::Command::Failed
          puts "No existing bundle found, proceeding with fresh installation"
        end
        
        # Clear any existing bundle config that might interfere
        puts "Clearing bundle config..."
        execute :bundle, "config --delete deployment", raise_on_non_zero_exit: false
        execute :bundle, "config --delete path", raise_on_non_zero_exit: false
        execute :bundle, "config --delete without", raise_on_non_zero_exit: false
        
        # Set up fresh bundle configuration
        puts "Setting up bundle configuration..."
        execute :bundle, "config set deployment 'true'"
        execute :bundle, "config set path '#{shared_path}/bundle'"
        execute :bundle, "config set without 'development test'"
      end
    end
  end
  
  desc "Diagnose bundler issues on the server"
  task :diagnose do
    on roles(:app) do
      within release_path do
        puts "=== Bundler Diagnosis ==="
        puts "Checking bundler version..."
        execute :bundle, "--version"
        puts "Checking gem environment..."
        execute :gem, "env"
        puts "Checking bundle config..."
        execute :bundle, "config"
        puts "Checking bundle path..."
        execute :bundle, "show rake"
        puts "Checking shared bundle path..."
        execute :ls, "-la #{shared_path}/bundle"
      end
    end
  end
  
  desc "Clean and reinstall bundle"
  task :clean_install do
    on roles(:app) do
      within release_path do
        puts "=== Cleaning and reinstalling bundle ==="
        puts "Removing existing bundle..."
        execute :rm, "-rf #{shared_path}/bundle"
        puts "Clearing bundle config..."
        execute :bundle, "config --delete deployment", raise_on_non_zero_exit: false
        execute :bundle, "config --delete path", raise_on_non_zero_exit: false
        execute :bundle, "config --delete without", raise_on_non_zero_exit: false
        puts "Setting up fresh bundle configuration..."
        execute :bundle, "config set deployment 'true'"
        execute :bundle, "config set path '#{shared_path}/bundle'"
        execute :bundle, "config set without 'development test'"
        puts "Installing bundle..."
        execute :bundle, "install"
      end
    end
  end
  
  desc "Fix deployment issues by ensuring proper environment setup"
  task :fix_deployment do
    on roles(:app) do
      within release_path do
        puts "=== Fixing deployment issues ==="
        
        # Ensure bundler is at the correct version
        puts "Ensuring bundler version..."
        execute :gem, "install bundler -v 2.1.4"
        
        # Clean everything and start fresh
        puts "Cleaning existing bundle..."
        execute :rm, "-rf #{shared_path}/bundle", raise_on_non_zero_exit: false
        
        # Clear all bundle config
        puts "Clearing bundle configuration..."
        execute :bundle, "config --delete deployment", raise_on_non_zero_exit: false
        execute :bundle, "config --delete path", raise_on_non_zero_exit: false
        execute :bundle, "config --delete without", raise_on_non_zero_exit: false
        
        # Set up fresh configuration
        puts "Setting up fresh bundle configuration..."
        execute :bundle, "config set deployment 'true'"
        execute :bundle, "config set path '#{shared_path}/bundle'"
        execute :bundle, "config set without 'development test'"
        
        # Install bundle
        puts "Installing bundle..."
        execute :bundle, "install"
        
        puts "Deployment environment should now be fixed!"
      end
    end
  end
end

# Hook the environment setup to run before bundle install
before "bundler:install", "bundler:setup_environment" 