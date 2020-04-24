module API
  module V1
    class Users < Grape::API
      
      include API::V1::Defaults

      resource :users do
           
        #------------------------------------------------------
        desc "Create a new user"
        post do

          user = User.new( user_params )
          if user.save
            expose user
          else
            Rails.logger.warn("==> Unable to save user")
            warden.custom_failure! # TODO: warden is undefined
            error! :forbidden, metadata: {reason: 'User could not be created. Possibly due to duplicate email address.', error: user.errors}
            # responds :json => user.errors, :status => 422
          end

        end

        #------------------------------------------------------
        desc "Return a user"
        params do
          requires :id, type: String, desc: "ID of the user"
        end
        
        get ":id" do
          User.where(id: permitted_params[:id]).first! || current_resource_owner
        end

        #------------------------------------------------------
        desc "Update a user"
        params do
          requires :id, type: String, desc: "ID of the user"
        end

        put ":id" do

          @user = User.find(params[:id])

          if @user.nil?
            error! :bad_request, metadata: {reason: 'User could not be found'}
          elsif @user != current_resource_owner
            error! :bad_request, metadata: {reason: 'User is not the signed-in user'}
          elsif @user.update_attributes( user_params )
            expose @user
          else
            error! :bad_request, metadata: {reason: 'User could not be updated'}
          end

        end

      end
    end
  end
end



# -- Old way using Rocket Pants ------

  # Scopes
  # before_action only: [:update, :show] do
  #   doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
  # end

  # version 1

  # def create
  #   user = User.new( user_params )
  #   if user.save
  #     expose user
  #   else
  #     Rails.logger.warn("==> Unable to save user")
  #     warden.custom_failure! # TODO: warden is undefined
  #     error! :forbidden, metadata: {reason: 'User could not be created. Possibly due to duplicate email address.', error: user.errors}
  #     # responds :json => user.errors, :status => 422
  #   end
  # end


  # def update
  #   @user = User.find(params[:id])

  #   if @user.nil?
  #     error! :bad_request, metadata: {reason: 'User could not be found'}
  #   elsif @user != current_resource_owner
  #     error! :bad_request, metadata: {reason: 'User is not the signed-in user'}
  #   elsif @user.update_attributes( user_params )
  #     expose @user
  #   else
  #     error! :bad_request, metadata: {reason: 'User could not be updated'}
  #   end
  # end

  # private

  # def user_params
  #   params.require(:user)
  #     .permit(:login, :email, :name, :password, :password_confirmation, :current_password,
  #             :identity_url, :remember_me, :newsletters, :reminder_freq, :last_reminder,
  #             :church, :group, :country, :american_state, :show_echo, :max_interval,
  #             :mnemonic_use, :all_refs, :referred_by, :auto_work_load, :show_email,
  #             :provider, :uid, :translation, :time_allocation, :quiz_alert,
  #             :device_token, :device_type)
  # end

# -------


