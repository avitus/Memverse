namespace :bundler do
  desc "Upgrade bundler to the latest version"
  task :upgrade do
    on roles(:app) do
      within release_path do
        execute :gem, "install bundler -v 2.1.4"
      end
    end
  end
end

# Hook the bundler upgrade to run before bundle install
before "bundler:install", "bundler:upgrade" 