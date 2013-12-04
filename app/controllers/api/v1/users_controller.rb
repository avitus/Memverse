class Api::V1::UsersController < Api::V1::ApiController

  doorkeeper_for :all  # Require access token for all actions

  version 1

  def show
    expose User.find( params[:id] ) || current_resource_owner
  end

end