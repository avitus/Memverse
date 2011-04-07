require 'bundler/capistrano'
require 'thinking_sphinx/deploy/capistrano'

##############################################################
##  Application
##############################################################
set :user, 'andyvitus'                                        # Your hosting account's username
set :domain, 'memverse.com'                                   # Hosting servername where your account is located
set :project, 'Memverse'                                      # Your application as its called in the repository
set :application, 'staging.memverse.com'                      # Your app's location (domain or subdomain)
set :applicationdir, "/home/#{user}/#{application}"           # The location of your application on your hosting (may differ for each hosting provider)

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

# set :scm_passphrase, "pa$$word"                             # The deploy user's password
# set :git_enable_submodules, 1                               # if you have vendored rails
# set :git_shallow_clone, 1

##############################################################
##  Deployment Config
##############################################################
set :deploy_to, applicationdir                                # deploy to directory set above
set :deploy_via, :remote_cache                                # Remote caching will keep a local git repo on the server you’re deploying to and simply run a fetch from that rather than an entire clone. This is probably the best option as it will only fetch the changes since the last.
default_run_options[:pty] = true                              # Forgo errors when deploying from windows, Must be set for the password prompt from git to work
set :chmod755, "app config db lib public vendor script script/* public/disp*"
set :use_sudo, false
set :rails_env, "staging"

##############################################################
##  Authentication
##############################################################
ssh_options[:keys] = %w(/home/avitus/.ssh/id_rsa)
ssh_options[:paranoid] = false
default_run_options[:pty] = true 
ssh_options[:forward_agent] = true                            # Use agent forwarding to simplify key management in order to use local keys
# ssh_options[:verbose] = :debug
# ssh_options[:port] = 22

##############################################################
##  Staging
##############################################################
set :stages, %w(dev1 dev2 testing staging production)
set :default_stage, "staging"
require File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems/capistrano-ext-1.2.1/lib/capistrano/ext/multistage")

##############################################################
##  Hooks
##############################################################
after "deploy:update_code", "deploy:symlink_db" #, "deploy:set_rails_env"

# before "deploy:update_code", "thinking_sphinx:stop"
after "deploy:update_code", "deploy:symlink_sphinx_indexes"
# after "deploy:update_code", "thinking_sphinx:configure"
# after "deploy:update_code", "thinking_sphinx:start"

##############################################################
##  Database config and restart
##############################################################
namespace :deploy do  
  desc "Symlinks the database.yml"                            # Link in the database config
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
  
  desc "Symlink the Sphinx index"
  task :symlink_sphinx_indexes, :roles => [:app] do
	run "ln -nfs #{deploy_to}/shared/db/sphinx #{release_path}/db"
  end  

  desc "Create asset packages for production" 
  task :after_update_code, :roles => [:web] do                 # Compress and minify javascript and css files
    run <<-EOF
    cd #{release_path} && rake asset:packager:build_all
    EOF
  end  

  desc "Restarting mod_rails with restart.txt"                # Restart passenger on deploy
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
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
##  Hoptoad
##############################################################
Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end

require 'hoptoad_notifier/capistrano'
