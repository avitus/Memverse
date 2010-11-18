set :user, 'andyvitus'                                # Your hosting account's username
set :domain, 'memverse.com'                           # Hosting servername where your account is located
set :project, 'Memverse'                              # Your application as its called in the repository
set :application, 'staging.memverse.com'              # Your app's location (domain or subdomain)
set :applicationdir, "/home/#{user}/#{application}"   # The location of your application on your hosting (may differ for each hosting provider)

# version control config
set :scm, 'git'
set :scm_passphrase, "veetle77"  # The deploy user's password
set :repository,  "git@github.com:avitus/Memverse.git" # Your git repository location

# set :git_enable_submodules, 1 # if you have vendored rails
set :branch, 'master'  # tell cap the branch to checkout during deployment
# set :git_shallow_clone, 1
set :scm_verbose, true
# roles (servers)
role :web, domain
role :app, domain
role :db,  domain, :primary => true
# deploy config
set :deploy_to, applicationdir # deploy to directory set above
set :deploy_via, :remote_cache # Remote caching will keep a local git repo on the server you’re deploying to and simply run a fetch from that rather than an entire clone. This is probably the best option as it will only fetch the changes since the last.
# additional settings
default_run_options[:pty] = true  # Forgo errors when deploying from windows, Must be set for the password prompt from git to work
set :chmod755, "app config db lib public vendor script script/* public/disp*"
set :use_sudo, false

# If having problems with SSH authentication
ssh_options[:keys] = %w(/home/avitus/.ssh/id_rsa)
ssh_options[:paranoid] = false
# ssh_options[:port] = 22
default_run_options[:pty] = true 
# ssh_options[:verbose] = :debug

# f you’re using your own private keys for git you might want to tell Capistrano to use agent forwarding with this command. 
# Agent forwarding can make key management much simpler as it uses your local keys instead of keys installed on the server.
# ssh_options[:forward_agent] = true

# Original below this line ---------

set :stages, %w(staging production)
set :default_stage, "staging"
require File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems/capistrano-ext-1.2.1/lib/capistrano/ext/multistage")

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

Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end

require 'hoptoad_notifier/capistrano'
