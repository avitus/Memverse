##############################################################
##	Application
##############################################################
set :user, 'alexcwatt'
set :application, 'dev2.memverse.com'                         # Your app's location (domain or subdomain)
set :applicationdir, "/home/#{user}/#{application}"           # The location of your application on your hosting (may differ for each hosting provider)
set :deploy_to, applicationdir

##############################################################
##	Settings
##############################################################
set :rails_env, "development" 

##############################################################
##  Authentication
##############################################################
ssh_options[:keys] = %w(/home/alexcwatt/.ssh/id_rsa)

##############################################################
##	Git
##############################################################
#
#set :scm, :git
#set :branch, "master"
#set :scm_passphrase, "pa$$word"
set :repository,  "git@github.com:alexcwatt/Memverse.git"        # Your git repository location
set :branch, $1 if `git branch` =~ /\* (\S+)\s/m                 # Deploy from same branch as local branch


