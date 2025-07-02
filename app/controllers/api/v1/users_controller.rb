class Api::V1::UsersController < Api::V1::ApiController

  include Devise::Controllers::Helpers  # Needed to support custom failure_app for Warden

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/users' do

    operation :post do
      key :description, 'Creates a new user'
      key :operationId, 'createUser'
      key :produces, ['application/json']
      key :tags, ['user']
      parameter do
        key :name, :name
        key :in, :query
        key :description, 'User name'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :email
        key :in, :query
        key :description, 'User email'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :password
        key :in, :query
        key :description, 'User password'
        key :required, true
        key :type, :string
      end      
      security do
        key :oauth2, ['write admin']
      end
      response 200 do
        key :description, 'User response'
        schema do
          key :'$ref', :User
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end

  end

  swagger_path '/users/{id}' do

    operation :get do
      
      key :description, 'Returns a single user'
      key :operationId, 'findUserById'
      key :tags, ['user']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID of user to fetch'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['public read write admin']
      end
      response 200 do
        key :description, 'User response'
        schema do
          key :'$ref', :User
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :User
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end

    operation :put do
      key :description, 'Partial updates to a user'
      key :operationId, 'updateUserById'
      key :tags, ['user']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID of user to update'
        key :required, true
        key :type, :integer
        key :format, :int64
        # schema do
        #   key :'$ref', :UserInput
        # end
      end
      security do
        key :oauth2, ['admin write read public']
      end
      response 200 do
        key :description, 'User response'
        schema do
          key :'$ref', :User
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :User
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Docs DSL [END]
  # ----------------------------------------------------------------------------------------------------------

  # Scopes -- this is the new way which replaces doorkeeper_for 
  before_action only: [:update, :show] do
    doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
  end

  def create
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

  def show
    expose User.find( params[:id] ) || current_resource_owner
  end

  def update
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

  private

  def user_params
    params.require(:user)
      .permit(:login, :email, :name, :password, :password_confirmation, :current_password,
              :identity_url, :remember_me, :newsletters, :reminder_freq, :last_reminder,
              :church, :group, :country, :american_state, :show_echo, :max_interval,
              :mnemonic_use, :all_refs, :referred_by, :auto_work_load, :show_email,
              :provider, :uid, :translation, :time_allocation, :quiz_alert,
              :device_token, :device_type)
  end

end
