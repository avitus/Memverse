require 'rails_helper'
require 'base64'

# The shipped iOS and Flutter/Android clients authenticate with the OAuth
# `password` grant and parse neither `expires_in` nor `refresh_token`. These
# specs pin the compatibility shim that keeps them working while the PWA is
# held to authorization code + PKCE. Delete this file when the shim goes.
RSpec.describe 'Legacy password grant compatibility', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:user_password) { 'please' } # matches the :user factory

  # Mirrors the Flutter/Android client, which sends client_id and client_secret
  # as form fields (anirac-tech/memverse_project, auth_api.dart).
  let(:android_client) do
    Doorkeeper::Application.create!(name: 'Legacy Android', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                    confidential: true, scopes: 'public read write')
  end

  # Mirrors the iOS client, which sends client_id as a form field and
  # client_id:secret in an HTTP Basic header (avitus/Memverse_iOS, HTTPHelper.swift).
  let(:ios_client) do
    Doorkeeper::Application.create!(name: 'Legacy iOS', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                    confidential: true, scopes: 'public read write')
  end

  def password_grant(client, password: user_password, secret: nil)
    params = { grant_type: 'password', username: user.email, password: password, client_id: client.uid }
    params[:client_secret] = secret if secret
    post '/oauth/token', params: params
  end

  def ios_password_grant(password: user_password)
    basic = Base64.strict_encode64("#{ios_client.uid}:#{ios_client.secret}")
    post '/oauth/token',
         params: { grant_type: 'password', username: user.email, password: password, client_id: ios_client.uid },
         headers: { 'Authorization' => "Basic #{basic}" }
  end

  describe 'the shipped mobile clients' do
    it 'issues an access token to the Android client authenticating with form fields' do
      password_grant(android_client, secret: android_client.secret)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('access_token')
    end

    it 'issues an access token to the iOS client authenticating with HTTP Basic' do
      ios_password_grant

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('access_token')
    end

    it 'issues non-expiring tokens, since neither client can refresh' do
      ios_password_grant

      expect(response.parsed_body).not_to include('expires_in')
      token = Doorkeeper::AccessToken.find_by(token: response.parsed_body.fetch('access_token'))
      expect(token.expires_in).to be_nil
      expect(token).not_to be_expired
    end

    it 'still refuses an incorrect password' do
      ios_password_grant(password: 'not-the-password')

      expect(response).not_to have_http_status(:ok)
      expect(response.parsed_body).not_to include('access_token')
    end

    it 'still refuses an incorrect client secret' do
      password_grant(android_client, secret: 'not-the-secret')

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('invalid_client')
    end
  end

  describe 'the PWA client' do
    it 'is refused the password grant and must use authorization code + PKCE' do
      password_grant(PwaOauthApplication.ensure!)

      # RFC 6749 s5.2: the client is authenticated but not permitted this grant.
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('unauthorized_client')
      expect(response.parsed_body).not_to include('access_token')
    end
  end

  describe 'the PWA authorization code flow is unaffected' do
    let(:redirect_uri) { 'https://avitus.github.io/Memverse/authentication/login-callback' }
    let(:verifier) { 'memverse-pwa-pkce-verifier-with-at-least-43-characters' }

    it 'still issues 2 hour access tokens with a rotating refresh token' do
      application = PwaOauthApplication.ensure!
      grant = Doorkeeper::AccessGrant.create!(
        resource_owner_id: user.id, application_id: application.id,
        token: SecureRandom.hex(32), expires_in: 10.minutes.to_i, redirect_uri: redirect_uri,
        scopes: 'public read write',
        code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false),
        code_challenge_method: 'S256'
      )

      post '/oauth/token', params: { grant_type: 'authorization_code', client_id: application.uid,
                                     code: grant.token, redirect_uri: redirect_uri, code_verifier: verifier }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('access_token', 'refresh_token')
      expect(response.parsed_body['expires_in']).to be_between(119.minutes.to_i, 2.hours.to_i)
    end
  end
end
