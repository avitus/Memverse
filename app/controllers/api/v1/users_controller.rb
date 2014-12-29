class Api::V1::UsersController < Api::V1::ApiController

  doorkeeper_for :all  # Require access token for all actions

  version 1

  def show
    expose User.find( params[:id] ) || current_resource_owner
  end

  def update
    @user = User.find(params[:id])

    if @user.nil?
      error! :bad_request, metadata: {reason: 'User could not be found'}
    elsif @user != current_resource_owner
      error! :bad_request, metadata: {reason: 'User is not the signed-in user'}
    elsif @user.update_attributes(params[:user])
      expose @user
    else
      error! :bad_request, metadata: {reason: 'User could not be updated'}
    end
  end

  private

  def user_params
     params.require(:user).permit(:name, :reminder_freq, :language, :show_echo,
      :time_allocation, :max_interval, :gender, :translation)
  end

end
