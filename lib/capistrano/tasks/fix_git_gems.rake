namespace :bundler do
  desc "Fix git-based gems deployment issues"
  task :fix_git_gems do
    on roles(:app) do
      within shared_path do
        # Set bundler config to disable shallow clones for git gems
        execute :bundle, "config set --local disable_local_branch_check true"
        execute :bundle, "config set --local git.allow_insecure true"
        
        # Alternative: Set environment variable to disable shallow clones
        with BUNDLE_GIT__ALLOW_INSECURE: "true" do
          info "Configured bundler to handle git gems properly"
        end
      end
    end
  end
  
  desc "Clear git gem cache"
  task :clear_git_cache do
    on roles(:app) do
      within shared_path do
        # Clear CKEditor git cache
        execute :rm, "-rf", "#{shared_path}/bundle/ruby/3.2.0/cache/bundler/git/ckeditor-*"
        execute :rm, "-rf", "#{shared_path}/bundle/ruby/3.2.0/bundler/gems/ckeditor-*"
        info "Cleared git gem cache"
      end
    end
  end
end

# Hook into Capistrano deployment flow
before "bundler:install", "bundler:fix_git_gems"

# Optional: Clear cache before install if needed
# before "bundler:install", "bundler:clear_git_cache"