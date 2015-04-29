# module Api::V1

  class Api::V1::CredentialsController < Api::V1::ApiController

	before_action only: [:me] do
		doorkeeper_authorize! :admin, :write, :read
	end
	
	respond_to    :json

    def me
      expose current_resource_owner
    end

  end # of class

# end # of module