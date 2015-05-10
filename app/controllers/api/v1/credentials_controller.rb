class Api::V1::CredentialsController < Api::V1::ApiController

	# ----------------------------------------------------------------------------------------------------------
	# Swagger-Blocks DSL [START]
	# ----------------------------------------------------------------------------------------------------------
	include Swagger::Blocks

	swagger_path '/me' do

		operation :get do	  
		  key :description, 'Returns credential for current user'
		  key :operationId, 'findCurrentUser'
		  key :tags, ['current_user']
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

	before_action only: [:me] do
		doorkeeper_authorize! :admin, :write, :read, :public # allow any of these scopes access (logical OR)
	end

	def me
		expose current_resource_owner
	end

end # of class

