# Temporary redesign app on martial-eagle, sharing only production data/uploads.
set :staging_preview, true
set :rails_env, 'staging'
set :branch, 'staging'
set :deploy_to, '/home/avitus/staging.memverse.com'
set :rvm_ruby_version, '3.2.6'
set :rvm_type, :user
set :rvm_custom_path, '/home/avitus/.rvm'
set :keep_releases, 3
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets public/assets public/ckeditor_assets public/uploads storage]
set :default_env, {
  path: '/home/avitus/.nvm/versions/node/v24.21.0/bin:$PATH',
  NODE_ENV: 'production',
  REDIS_URL: 'redis://127.0.0.1:6381/0',
  NEW_RELIC_AGENT_ENABLED: 'false'
}
server '64.23.176.115', user: 'avitus', roles: %w[app web]
set :ssh_options, {
  keys: [File.join(ENV.fetch('HOME'), '.ssh', 'id_ed25519')],
  forward_agent: true,
  auth_methods: %w[publickey]
}

# Never migrate the shared database, even if deploy:migrate is invoked directly.
Rake::Task['deploy:migrate'].clear
namespace :deploy do
  task :migrate do
    puts 'Staging uses the live schema; migrations are disabled.'
  end

  task :restart do
    on roles(:app) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end

# Legacy upgrade hooks mutate the shared Ruby installation and rebuild gems unnecessarily.
%w[bundler:setup_environment bundler:fix_git_gems bundler:configure_platform bundler:fix_nokogiri].each do |name|
  Rake::Task[name].clear
end
