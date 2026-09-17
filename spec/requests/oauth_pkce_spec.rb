require 'rails_helper'
require 'base64'
require 'digest'

RSpec.describe 'OAuth PKCE flow', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:redirect_uri) { 'https://avitus.github.io/Memverse/authentication/login-callback' }
  let(:application) do
    Doorkeeper::Application.create!(
      name: 'Memverse PWA',
      uid: SecureRandom.uuid,
      redirect_uri: redirect_uri,
      confidential: false,
      scopes: 'public read write'
    )
  end
  let(:verifier) { 'memverse-pwa-pkce-verifier-with-at-least-43-characters' }
  let(:challenge) do
    Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
  end

  def create_access_grant
    Doorkeeper::AccessGrant.create!(
      resource_owner_id: user.id,
      application_id: application.id,
      token: SecureRandom.hex(32),
      expires_in: 10.minutes.to_i,
      redirect_uri: redirect_uri,
      scopes: 'public read write',
      code_challenge: challenge,
      code_challenge_method: 'S256'
    )
  end

  it 'exchanges a PKCE authorization code without a client secret' do
    grant = create_access_grant

    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      client_id: application.uid,
      code: grant.token,
      redirect_uri: redirect_uri,
      code_verifier: verifier
    }

    expect(response).to have_http_status(:ok)
    token_response = response.parsed_body
    expect(token_response).to include('access_token', 'refresh_token')
    expect(token_response['expires_in']).to be_between(119.minutes.to_i, 2.hours.to_i)
    expect(Doorkeeper.config.force_pkce?).to be(true)
  end

  it 'rejects an authorization code without the matching PKCE verifier' do
    grant = create_access_grant

    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      client_id: application.uid,
      code: grant.token,
      redirect_uri: redirect_uri,
      code_verifier: 'incorrect-verifier-with-at-least-43-characters-long'
    }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body['error']).to eq('invalid_grant')
  end

  it 'rotates refresh tokens and rejects reuse of the previous token' do
    grant = create_access_grant
    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      client_id: application.uid,
      code: grant.token,
      redirect_uri: redirect_uri,
      code_verifier: verifier
    }
    original_refresh_token = response.parsed_body.fetch('refresh_token')

    post '/oauth/token', params: {
      grant_type: 'refresh_token',
      client_id: application.uid,
      refresh_token: original_refresh_token
    }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('refresh_token')).not_to eq(original_refresh_token)

    post '/oauth/token', params: {
      grant_type: 'refresh_token',
      client_id: application.uid,
      refresh_token: original_refresh_token
    }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body['error']).to eq('invalid_grant')
  end

  it 'revokes a token for a public client without a client secret' do
    access_token = Doorkeeper::AccessToken.create!(
      application: application,
      resource_owner_id: user.id,
      scopes: 'public read write'
    )

    post '/oauth/revoke', params: {
      token: access_token.token,
      client_id: application.uid
    }

    expect(response).to have_http_status(:ok)
    expect(access_token.reload).to be_revoked
  end
end
