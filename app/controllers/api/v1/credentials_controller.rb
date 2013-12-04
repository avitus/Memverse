# module Api::V1

  class Api::V1::CredentialsController < Api::V1::ApiController

    doorkeeper_for :all

    def me
      expose current_resource_owner
    end

  end # of class

# end # of module