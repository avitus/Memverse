# API endpoint for password reset functionality
class Api::V1::PasswordResetsController < Api::V1::ApiController

  include Swagger::Blocks

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Docs DSL [START]
  # https://github.com/fotinakis/swagger-blocks
  # ----------------------------------------------------------------------------------------------------------

  swagger_path '/password_resets' do

    operation :post do
      key :description, 'Request a password reset email'
      key :operationId, 'requestPasswordReset'
      key :produces, ['application/json']
      key :tags, ['password_reset']
      parameter do
        key :name, :email
        key :in, :query
        key :description, 'Email address of the user'
        key :required, true
        key :type, :string
      end
      response 200 do
        key :description, 'Password reset request successful'
        schema do
          key :type, :object
          property :response do
            key :type, :object
            property :message do
              key :type, :string
              key :description, 'Success message'
            end
          end
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

  swagger_path '/password_resets' do

    operation :put do
      key :description, 'Reset password with token'
      key :operationId, 'resetPassword'
      key :produces, ['application/json']
      key :tags, ['password_reset']
      parameter do
        key :name, :reset_password_token
        key :in, :query
        key :description, 'Password reset token from email'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :password
        key :in, :query
        key :description, 'New password'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :password_confirmation
        key :in, :query
        key :description, 'Password confirmation'
        key :required, true
        key :type, :string
      end
      response 200 do
        key :description, 'Password reset successful'
        schema do
          key :type, :object
          property :response do
            key :type, :object
            property :message do
              key :type, :string
              key :description, 'Success message'
            end
            property :user do
              key :type, :object
              property :id do
                key :type, :integer
                key :format, :int64
              end
              property :email do
                key :type, :string
              end
            end
          end
        end
      end
      response 422 do
        key :description, 'Validation error'
        schema do
          key :type, :object
          property :error do
            key :type, :string
          end
          property :message do
            key :type, :string
          end
          property :errors do
            key :type, :array
            items do
              key :type, :string
            end
          end
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

  # Password reset endpoints don't require authentication
  # No doorkeeper_authorize! call needed

  # POST /api/v1/password_resets
  # Request a password reset email
  def create
    user = User.find_by(email: params[:email])

    if user
      user.send_reset_password_instructions
      expose({ message: "Password reset instructions have been sent to #{params[:email]}." })
    else
      # Return success even if user not found (security best practice)
      expose({ message: "Password reset instructions have been sent to #{params[:email]}." })
    end
  end

  # PUT /api/v1/password_resets
  # Reset password with token
  def update
    user = User.reset_password_by_token(password_reset_params)

    if user.errors.empty?
      expose({
        message: "Password has been reset successfully.",
        user: {
          email: user.email,
          id: user.id
        }
      })
    else
      error!(:unprocessable_entity, metadata: {
        message: "Password reset failed",
        errors: user.errors.full_messages
      })
    end
  end

  private

  def password_reset_params
    params.permit(:reset_password_token, :password, :password_confirmation)
  end
end