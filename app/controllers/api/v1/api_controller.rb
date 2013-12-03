# Base controller for API
class Api::V1::ApiController < RocketPants::Base

  # See http://stackoverflow.com/questions/11383111/how-to-use-both-rocket-pants-and-doorkeeper-in-the-same-rails-application
  include ActionController::Head
  include Doorkeeper::Helpers::Filter

  # Returns the current resource owner, based on the token
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

end
