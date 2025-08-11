namespace :bundler do
  desc "Configure bundler for platform-specific gem compilation"
  task :configure_platform do
    on roles(:app) do
      within release_path do
        # Force Ruby platform for gems with native extensions
        # This ensures compatibility with older glibc versions
        execute :bundle, "config set --local force_ruby_platform true"
        info "Configured bundler to compile native gems from source"
      end
    end
  end
  
  desc "Fix Nokogiri platform issues"
  task :fix_nokogiri do
    on roles(:app) do
      within shared_path do
        # Check if Nokogiri is causing issues
        nokogiri_gems = capture(:find, "#{shared_path}/bundle/ruby/3.2.0/gems", "-name", "'nokogiri-*-linux*'", "-type", "d", "2>/dev/null || true")
        
        if nokogiri_gems && !nokogiri_gems.empty?
          info "Found precompiled Nokogiri gems that may be incompatible"
          
          # Remove precompiled versions
          execute :rm, "-rf", "#{shared_path}/bundle/ruby/3.2.0/gems/nokogiri-*-linux*"
          execute :rm, "-rf", "#{shared_path}/bundle/ruby/3.2.0/specifications/nokogiri-*-linux*.gemspec"
          execute :rm, "-rf", "#{shared_path}/bundle/ruby/3.2.0/extensions/*/3.2.0*/nokogiri-*"
          
          info "Removed precompiled Nokogiri gems"
        end
      end
    end
  end
end

# Hook into Capistrano deployment flow
before "bundler:install", "bundler:configure_platform"
before "bundler:install", "bundler:fix_nokogiri"