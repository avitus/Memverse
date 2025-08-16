set :rails_env, "production" 

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'memverse.com', user: 'avitus', roles: %w{app db web}
server 'www.memverse.com', user: 'avitus', roles: %w{app db web}

# Deploy from the main branch (production)
# Note: This inherits from config/deploy.rb which sets branch to 'main'
# set :branch, 'main'  # Commented out to use default from deploy.rb
set :rvm_ruby_version, '3.2.6'

# Additional linked directories for Rails 7 and Active Storage
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'public/ckeditor_assets',
  'public/uploads',     # Paperclip legacy
  'storage'            # Active Storage
)

# server 'memverse.com', user: 'avitus', roles: %w{app db web}, my_property: :my_value
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}

# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}

# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
set :ssh_options, {
	keys: [File.join(ENV["HOME"], ".ssh", "id_rsa")],
	forward_agent: true,
	auth_methods: %w(publickey password)
}

# Handle some weird issues with Sidekiq and Capistrano
# https://github.com/seuros/capistrano-sidekiq/issues/124
set :rvm_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl}

# Load NVM for asset compilation
# This ensures Node.js is available when running asset precompilation
namespace :deploy do
  namespace :assets do
    before :precompile, :setup_nvm do
      on roles(:app) do
        # Source NVM and set up the environment for asset compilation
        with rails_env: fetch(:rails_env) do
          execute :bash, '-c', 'source ~/.nvm/nvm.sh && nvm use default && which node'
        end
      end
    end
  end
end

# Alternative: Override the entire assets:precompile task to use NVM
Rake::Task["deploy:assets:precompile"].clear
namespace :deploy do
  namespace :assets do
    task :precompile do
      on roles(:app) do
        within release_path do
          with rails_env: fetch(:rails_env), path: "/home/avitus/.nvm/versions/node/v16.20.2/bin:$PATH" do
            execute :bundle, :exec, :rake, 'assets:precompile'
          end
        end
      end
    end
  end
end

# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
