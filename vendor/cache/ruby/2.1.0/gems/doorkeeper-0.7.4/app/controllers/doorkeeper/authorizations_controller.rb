module Doorkeeper
  class AuthorizationsController < ::Doorkeeper::ApplicationController
    before_filter :authenticate_resource_owner!

    def new
      if pre_auth.authorizable?
        if Doorkeeper::AccessToken.matching_token_for(pre_auth.client, current_resource_owner.id, pre_auth.scopes) || skip_authorization?
          auth = authorization.authorize
          redirect_to auth.redirect_uri
        else
          render :new
        end
      else
        render :error
      end
    end

    def show
    end

    # TODO: Handle raise invalid authorization
    def create
      auth = authorization.authorize

      if auth.redirectable?
        redirect_to auth.redirect_uri
      else
        render :json => auth.body, :status => auth.status
      end
    end

    def destroy
      auth = authorization.deny

      if auth.redirectable?
        redirect_to auth.redirect_uri
      else
        render :json => auth.body, :status => auth.status
      end
    end

  private

    def pre_auth
      @pre_auth ||= OAuth::PreAuthorization.new(Doorkeeper.configuration, server.client_via_uid, params)
    end

    def authorization
      @authorization ||= strategy.request
    end

    def strategy
      @strategy ||= server.authorization_request pre_auth.response_type
    end
  end
end
