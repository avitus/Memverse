require 'spec_helper_integration'

feature 'Token endpoint' do
  background do
    client_exists
    authorization_code_exists :application => @client, :scopes => "public"
  end

  scenario 'respond with correct headers' do
    post token_endpoint_url(:code => @authorization.token, :client => @client)
    should_have_header 'Pragma', 'no-cache'
    should_have_header 'Cache-Control', 'no-store'
    should_have_header 'Content-Type', 'application/json; charset=utf-8'
  end

  scenario 'accepts client credentials with basic auth header' do
    post token_endpoint_url(:code => @authorization.token, :redirect_uri => @client.redirect_uri),
                            {} ,
                            { 'HTTP_AUTHORIZATION' => basic_auth_header_for_client(@client) }

    should_have_json 'access_token', Doorkeeper::AccessToken.first.token
  end

  scenario 'returns null for expires_in when a permanent token is set' do
    config_is_set(:access_token_expires_in, nil)
    post token_endpoint_url(:code => @authorization.token, :client => @client)
    should_have_json 'access_token', Doorkeeper::AccessToken.first.token
    should_not_have_json 'expires_in'
  end

  scenario 'returns unsupported_grant_type for invalid grant_type param' do
    post token_endpoint_url(:code => @authorization.token, :client => @client, :grant_type => 'nothing')

    should_not_have_json 'access_token'
    should_have_json 'error', 'unsupported_grant_type'
    should_have_json 'error_description', translated_error_message('unsupported_grant_type')
  end

  scenario 'returns invalid_request if grant_type is missing' do
    post token_endpoint_url(:code => @authorization.token, :client => @client, :grant_type => '')

    should_not_have_json 'access_token'
    should_have_json 'error', 'invalid_request'
    should_have_json 'error_description', translated_error_message('invalid_request')
  end
end
