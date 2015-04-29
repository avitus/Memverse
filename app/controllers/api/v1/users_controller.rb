class Api::V1::UsersController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

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
        key :oauth2, ['read']
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
        key :oauth2, ['write admin']
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

  # doorkeeper_for :all  # Require access token for all actions

  # Scopes -- this is the new way which replaces doorkeeper_for 
  before_action -> { doorkeeper_authorize! :public }, only: :index
  before_action only: [:update, :show] do
    doorkeeper_authorize! :admin, :write, :read
  end


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
