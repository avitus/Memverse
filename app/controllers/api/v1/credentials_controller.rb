module Api::V1

  class CredentialsController < ApiController

    doorkeeper_for :all

    # respond_to :json

    def me
      respond_with current_resource_owner
    end

  end # of class

end # of module