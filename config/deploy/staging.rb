##############################################################
##	Application
##############################################################
#
#set :application, "Memverse"
#set :deploy_to, applicationdir
#
##############################################################
##	Settings
##############################################################
#
#default_run_options[:pty] = true
#ssh_options[:forward_agent] = true
#set :use_sudo, true
#set :scm_verbose, true
set :rails_env, "staging" 
#
##############################################################
##	Servers
##############################################################
#
#set :user, "andyvitus"
#set :domain, "ps19952.dreamhostps.com"
#server domain, :app, :web
#role :db, domain, :primary => true
#
##############################################################
##	Git
##############################################################
#
#set :scm, :git
set :branch, $1 if `git branch` =~ /\* (\S+)\s/m
#set :scm_user, 'andyvitus'
#set :scm_passphrase, "pa$$word"
#set :repository, "git@github.com:avitus/Memverse.git"
#set :deploy_via, :remote_cache
#
##############################################################
##	Passenger
##############################################################
#
# namespace :deploy do
#  desc "Create the database yaml file"
#  task :after_update_code do
#    db_config = <<-EOF
#    staging:    
#      adapter: mysql
#      encoding: utf8
#      username: root
#      password: 
#      database: bort_staging
#      host: localhost
#    EOF
#    
#    put db_config, "#{release_path}/config/database.yml"
#
#    #########################################################
#    # Uncomment the following to symlink an uploads directory.
#    # Just change the paths to whatever you need.
#    #########################################################
#    
#    # desc "Symlink the upload directories"
#    # task :before_symlink do
#    #   run "mkdir -p #{shared_path}/uploads"
#    #   run "ln -s #{shared_path}/uploads #{release_path}/public/uploads"
#    # end
#  end
#  
#  
#  [:start, :stop].each do |t|
#    desc "#{t} task is a no-op with mod_rails"
#    task t, :roles => :app do ; end
#  end
#  
# end
