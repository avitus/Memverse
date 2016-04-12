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

        key :name, :email
        key :in, :query
        key :description, 'User email'
        key :required, true
        key :type, :string

        key :name, :password
        key :in, :query
        key :description, 'User password'
        key :required, true
        key :type, :string

        schema do
          key :'$ref', :UserInput
        end

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

  version 1

  def create
    user = User.new( params[:user] )
    if user.save
      expose user
    else
      Rails.logger.warn("==> Unable to save user")
      warden.custom_failure! # TODO: warden is undefined
      responds :json => user.errors, :status => 422
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
