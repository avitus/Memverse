# config valid only for current version of Capistrano
lock '3.5.0'

set :user, 'avitus'
set :application, 'memverse.com'

set :repo_url, 'git@github.com:avitus/Memverse.git'
set :branch, 'master'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/avitus/memverse.com'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/ckeditor_assets')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:all), in: :groups, limit: 3, wait: 10 do

      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end

      within release_path do
        execute :touch, release_path.join('tmp/restart.txt')
      end

    end
  end

  after :publishing,  'deploy:restart'
  after :finishing,   'thinking_sphinx:index'
  after :finishing,   'thinking_sphinx:restart'
  after :finishing,   'deploy:cleanup'
  after :finished,    'airbrake:deploy'

end
