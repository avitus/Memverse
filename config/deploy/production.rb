##############################################################
##	Application
##############################################################

set :user, 'avitus'
set :application, '198.74.51.120'                        # Your app's location (domain or subdomain)
set :applicationdir, "/home/#{user}/#{application}"      # The location of your application on your hosting (may differ for each hosting provider)
set :deploy_to, applicationdir

##############################################################
##	Settings
##############################################################

set :rails_env, "production" 



