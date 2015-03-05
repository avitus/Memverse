require 'spec_helper_integration'

feature 'Authorization Code Flow' do
  background do
    config_is_set(:authenticate_resource_owner) { User.first || redirect_to('/sign_in') }
    client_exists
    create_resource_owner
    sign_in
  end

  scenario 'resource owner authorizes the client' do
    visit authorization_endpoint_url(:client => @client)
    click_on "Authorize"

    access_grant_should_exist_for(@client, @resource_owner)

    i_should_be_on_client_callback(@client)

    url_should_have_param("code", Doorkeeper::AccessGrant.first.token)
    url_should_not_have_param("state")
    url_should_not_have_param("error")
  end

  scenario 'resource owner authorizes using test url' do
    @client.redirect_uri = Doorkeeper.configuration.test_redirect_uri
    @client.save!
    visit authorization_endpoint_url(:client => @client)
    click_on "Authorize"

    access_grant_should_exist_for(@client, @resource_owner)

    i_should_see 'Authorization code:'
    i_should_see Doorkeeper::AccessGrant.first.token
  end

  scenario 'resource owner authorizes the client with state parameter set' do
    visit authorization_endpoint_url(:client => @client, :state => "return-me")
    click_on "Authorize"
    url_should_have_param("code", Doorkeeper::AccessGrant.first.token)
    url_should_have_param("state", "return-me")
  end

  scenario 'resource owner requests an access token with authorization code' do
    visit authorization_endpoint_url(:client => @client)
    click_on "Authorize"

    authorization_code = Doorkeeper::AccessGrant.first.token
    post token_endpoint_url(:code => authorization_code, :client => @client)

    access_token_should_exist_for(@client, @resource_owner)

    should_not_have_json 'error'

    should_have_json 'access_token', Doorkeeper::AccessToken.first.token
    should_have_json 'token_type',   "bearer"
    should_have_json 'expires_in',   Doorkeeper::AccessToken.first.expires_in
  end

  context 'with scopes' do
    background do
      default_scopes_exist  :public
      optional_scopes_exist :write
    end

    scenario 'resource owner authorizes the client with default scopes' do
      visit authorization_endpoint_url(:client => @client)
      click_on "Authorize"
      access_grant_should_exist_for(@client, @resource_owner)
      access_grant_should_have_scopes :public
    end

    scenario 'resource owner authorizes the client with required scopes' do
      visit authorization_endpoint_url(:client => @client, :scope => "public write")
      click_on "Authorize"
      access_grant_should_have_scopes :public, :write
    end

    scenario 'resource owner authorizes the client with required scopes (without defaults)' do
      visit authorization_endpoint_url(:client => @client, :scope => "write")
      click_on "Authorize"
      access_grant_should_have_scopes :write
    end

    scenario 'new access token matches required scopes' do
      visit authorization_endpoint_url(:client => @client, :scope => "public write")
      click_on "Authorize"

      authorization_code = Doorkeeper::AccessGrant.first.token
      post token_endpoint_url(:code => authorization_code, :client => @client)

      access_token_should_exist_for(@client, @resource_owner)
      access_token_should_have_scopes :public, :write
    end

    scenario 'returns new token if scopes have changed' do
      client_is_authorized(@client, @resource_owner, :scopes => "public write")
      visit authorization_endpoint_url(:client => @client, :scope => "public")
      click_on "Authorize"

      authorization_code = Doorkeeper::AccessGrant.first.token
      post token_endpoint_url(:code => authorization_code, :client => @client)

      Doorkeeper::AccessToken.count.should be(2)

      should_have_json 'access_token', Doorkeeper::AccessToken.last.token
    end
  end
end
