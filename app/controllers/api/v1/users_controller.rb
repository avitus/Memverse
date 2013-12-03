class Api::V1::UsersController < Api::V1::ApiController

  doorkeeper_for :all  # Require access token for all actions

  version 1

  def index
    expose User.all # Not what we'd actually do, of course.
  end

  def show
    expose User.find(params[:id])
  end

end