require 'bundler/capistrano'
require 'thinking_sphinx/capistrano'                            # Support for search index
require 'sidekiq/capistrano'                                    # Delayed jobs

load 'deploy/assets'                                            # Precompile assets

##############################################################
##  RVM Integration
##############################################################
# $:.unshift(File.expand_path('./lib', ENV['rvm_path']))        # Add RVM's lib directory to the load path.
# require "rvm/capistrano"                                      # Load RVM's capistrano plugin.
# set :rvm_type, :user                                          # use an rvm install in the deploying users home directory
# set :rvm_ruby_string, "ruby-1.9.2-p290@pariday"

##############################################################
##  Application
##############################################################
set :user, 'avitus'                                           # Your hosting account's username
set :domain, 'memverse.com'                                   # Hosting servername where your account is located
set :project, 'Memverse'                                      # App name in the repository
set :application, 'memverse.com'                              # App's location (domain or subdomain)
set :applicationdir, "/home/#{user}/#{application}"           # App location

##############################################################
##  Servers
##############################################################
role :web, domain
role :app, domain
role :db,  domain, :primary => true

##############################################################
##  Git
##############################################################
set :scm, 'git'
set :repository,  "git@github.com:avitus/Memverse.git"        # Your git repository location
set :branch, 'master'                                         # tell cap the branch to checkout during deployment
set :scm_verbose, true
set :keep_releases, 5                                         # Keep only five most recent releases
# set :scm_passphrase, "pa$$word"                             # The deploy user's password
# set :git_shallow_clone, 1

##############################################################
##  Deployment Config
##############################################################
set :deploy_to, applicationdir                                # deploy to directory set above
set :deploy_via, :remote_cache                                # Remote caching will keep a local git repo on the server you’re deploying to and simply run a fetch from that rather than an entire clone. This is probably the best option as it will only fetch the changes since the last.
default_run_options[:pty] = true                              # Forgo errors when deploying from windows, Must be set for the password prompt from git to work
set :chmod755, "app config db lib public vendor script script/* public/disp*"
set :use_sudo, false
set :rails_env, "production"

##############################################################
##  Authentication
##############################################################
ssh_options[:keys] = ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]
ssh_options[:paranoid] = false
default_run_options[:pty] = true
ssh_options[:forward_agent] = true                            # Use agent forwarding to simplify key management in order to use local keys
# ssh_options[:verbose] = :debug
# ssh_options[:port] = 22

##############################################################
##  Staging
##############################################################
set :stages, %w(dev testing staging production)
set :default_stage, "production"
# require File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems/capistrano-ext-1.2.1/lib/capistrano/ext/multistage")

##############################################################
##  Hooks
##############################################################
before "deploy:assets:precompile", "deploy:symlink_config", "deploy:symlink_bloggity"
after "deploy", "deploy:refresh_sitemaps", "deploy:cleanup"

##############################################################
##  Database config and restart
##############################################################
namespace :deploy do
  desc "Symlinks database.yml and secret_token.rb"            # Link in the database and secret config
  task :symlink_config, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{latest_release}/config/database.yml"
    run "ln -nfs #{deploy_to}/shared/config/initializers/secret_token.rb #{latest_release}/config/initializers/secret_token.rb"
  end

  desc "Symlinks the bloggity uploads"                        # Link in the bloggity uploads
  task :symlink_bloggity, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/public/ckeditor_assets #{latest_release}/public/ckeditor_assets"
  end

  desc "Restarting mod_rails with restart.txt"                # Restart passenger on deploy
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Generate sitemap"
  task :refresh_sitemaps do
    run "cd #{latest_release} && RAILS_ENV=#{rails_env} bundle exec rake sitemap:refresh"
  end

end

##############################################################
##  Database tasks
##############################################################
namespace :db do
  desc 'Dumps the production database to db/production_data.sql on the remote server'
  task :remote_db_dump, :roles => :db, :only => { :primary => true } do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} db:database_dump --trace"
  end

  desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
  task :remote_db_download, :roles => :db, :only => { :primary => true } do
    execute_on_servers(options) do |servers|
      self.sessions[servers.first].sftp.connect do |tsftp|
        tsftp.download!("#{deploy_to}/#{current_dir}/db/production_data.sql", "db/production_data.sql")
      end
    end
  end

  desc 'Cleans up data dump file'
  task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do
    execute_on_servers(options) do |servers|
      self.sessions[servers.first].sftp.connect do |tsftp|
        tsftp.remove! "#{deploy_to}/#{current_dir}/db/production_data.sql"
      end
    end
  end

  desc 'Dumps, downloads and then cleans up the production data dump'
  task :remote_db_runner do
    remote_db_dump
    remote_db_download
    remote_db_cleanup
  end
end

##############################################################
##  Error Notification
##############################################################
require './config/boot'
require 'airbrake/capistrano/tasks'
