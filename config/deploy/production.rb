##############################################################
##	Application
##############################################################

set :user, 'andyvitus'
set :application, 'memverse.com'                              # Your app's location (domain or subdomain)
set :applicationdir, "/home/#{user}/#{application}"           # The location of your application on your hosting (may differ for each hosting provider)
set :deploy_to, applicationdir

##############################################################
##	Settings
##############################################################
#
#default_run_options[:pty] = true
#ssh_options[:forward_agent] = true
#set :use_sudo, true
#set :scm_verbose, true
set :rails_env, "production" 

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
#set :branch, "master"
#set :scm_user, 'avitus'
#set :scm_passphrase, "pa$$word"
#set :repository, "git@github.com:avitus/Memverse.git"
#set :deploy_via, :remote_cache
#
##############################################################
##	Passenger
##############################################################
#
#namespace :deploy do
#  desc "Create the database yaml file"
#  task :after_update_code do
#    db_config = <<-EOF
#    production:    
#      adapter: mysql
#      encoding: utf8
#      username: root
#      password: 
#      database: bort_production
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
#  
#  end
#    
#  # Restart passenger on deploy
#  desc "Restarting mod_rails with restart.txt"
#  task :restart, :roles => :app, :except => { :no_release => true } do
#    run "touch #{current_path}/tmp/restart.txt"
#  end
#  
#  [:start, :stop].each do |t|
#    desc "#{t} task is a no-op with mod_rails"
#    task t, :roles => :app do ; end
#  end
#  
#end
