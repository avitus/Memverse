# config/initializers/application_settings.rb
# ========================
# Tells Rails to load our ApplicationSettings module and then
# populates our config class variable with data from our application_settings.yml file
# From here on in, we should be able to call:
#
#    ApplicationSettings.config['url']
#
# and have it return our config option...

# require "#{Dir.pwd}/lib/application_settings.rb"
ApplicationSettings.config = YAML.load_file("config/application_settings.yml")[Rails.env]