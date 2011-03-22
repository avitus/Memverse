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

set :rails_env, "production" 



