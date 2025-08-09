# Add these lines to your Capfile for Rails 7 deployment

# Load Rails 7 specific tasks
Dir.glob('lib/capistrano/tasks/rails7*.rake').each { |r| import r }

# Uncomment these if you're using them:
# require 'capistrano/puma'
# require 'capistrano/puma/workers'
# require 'capistrano/puma/nginx'

# For Active Storage file migrations
# require 'capistrano/rails/migrations'

# For systemd service management
# require 'capistrano/systemd/multiservice'

# If using whenever for cron jobs
# require 'whenever/capistrano'