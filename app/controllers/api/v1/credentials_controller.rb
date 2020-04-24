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

	# TODO: This incorrectly resolves to /1/oauth/token when it should be /oauth/token i.e. no version number
	# In reality, this probably shouldn't be listed as an API endpoint, but rather should be included in the auth
	# dialog box as per the Petstore example on Swagger.io
	swagger_path '/oauth/token' do 

		operation :post do
		  key :description, 'Request an API access token. This access token should be used for all future requests as per the Oauth2 Password Flow.'
      	  key :operationId, 'requestAccessToken'
          key :tags, ['authorization']
          parameter do
            key :name, :grant_type
            key :in, :path
            key :description, 'Password flow is best option for supporting a mobile app'
            key :required, true
            key :type, :string
          end
          parameter do
            key :name, :username
            key :in, :path
            key :description, 'User name on Memverse.com (email address)'
            key :required, true
            key :type, :string
          end
          parameter do
            key :name, :password
            key :in, :path
            key :description, 'User password on Memverse.com'
            key :required, true
            key :type, :string
          end
          parameter do
            key :name, :client_id
            key :in, :path
            key :description, 'Contact admin@memverse.com to get a client_id'
            key :required, true
            key :type, :string
          end           
		  response 200 do
		    key :description, 'API access token'
		    schema do
		      key :'$ref', :User
		    end
		  end
		end		

	end

	# ----------------------------------------------------------------------------------------------------------
	# Swagger-Docs DSL [END]
	# ----------------------------------------------------------------------------------------------------------

	# before_action only: [:me] do
	# 	doorkeeper_authorize! :admin, :write, :read, :public # allow any of these scopes access (logical OR)
	# end

	# def me
	# 	expose current_resource_owner # equivalent to current user
	# end

end # of class

