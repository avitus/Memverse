# Base controller for API
# class Api::V1::ApiController < RocketPants::Base

#   # See http://stackoverflow.com/questions/11383111/how-to-use-both-rocket-pants-and-doorkeeper-in-the-same-rails-application
#   # ... and also https://github.com/doorkeeper-gem/doorkeeper/wiki/ActionController::Metal-with-doorkeeper
#   include ActionController::Head
#   include Doorkeeper::Rails::Helpers

#   # Airbrake support
#   # use_named_exception_notifier :airbrake

#   #------------- Private below this line -------------------------------------------------------------------------------------
#   private

#   # Returns the current resource owner, based on the token
#   def current_resource_owner
#     User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
#   end

# end
