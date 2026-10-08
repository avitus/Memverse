require 'rails_helper'
require 'base64'
require 'digest'

RSpec.describe SwaggerOauthApplication do
  let(:callback) { 'https://www.memverse.com/api/o2c.html' }

  it 'uses the client id hard-coded in the Swagger UI page' do
    index = Rails.root.join('public/api/index.html').read

    expect(index).to include(%(clientId: "#{described_class::UID}"))
  end

  context 'when the client does not exist yet' do
    it 'creates a public client with the Swagger PKCE callback' do
      application = described_class.ensure!

      expect(application.uid).to eq(described_class::UID)
      expect(application).not_to be_confidential
      expect(application.redirect_uri.split).to eq([callback])
      expect(application.scopes.to_s).to eq('public read write')
    end
  end

  context 'when a confidential client already exists' do
    let!(:existing) do
      Doorkeeper::Application.create!(
        name: 'Legacy Swagger client',
        uid: described_class::UID,
        redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
        confidential: true,
        scopes: 'public read write admin'
      )
    end

    it 'makes it public and adds the callback without removing anything' do
      application = described_class.ensure!

      expect(application.id).to eq(existing.id)
      expect(application).not_to be_confidential
      expect(application.redirect_uri.split).to eq(['urn:ietf:wg:oauth:2.0:oob', callback])
      expect(application.scopes.to_s).to eq('public read write admin')
      expect(application.name).to eq('Legacy Swagger client')
    end

    it 'still verifies the secret of any caller that sends one' do
      secret = existing.secret
      described_class.ensure!

      expect(Doorkeeper::Application.by_uid_and_secret(described_class::UID, secret)).to eq(existing)
      expect(Doorkeeper::Application.by_uid_and_secret(described_class::UID, 'wrong-secret')).to be_nil
    end

    it 'is idempotent' do
      described_class.ensure!
      described_class.ensure!

      expect(existing.reload.redirect_uri.split).to eq(['urn:ietf:wg:oauth:2.0:oob', callback])
    end
  end

  context 'when an existing redirect URI fails validation' do
    # Simulates a record saved before force_ssl_in_redirect_uri existed.
    let!(:existing) do
      Doorkeeper::Application.create!(
        name: 'Legacy Swagger client',
        uid: described_class::UID,
        redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
        confidential: true,
        scopes: 'public read write'
      ).tap { |application| application.update_column(:redirect_uri, 'http://www.memverse.com/api/o2c.html') }
    end

    it 'raises and leaves the stored record unchanged' do
      expect { described_class.ensure! }.to raise_error(ActiveRecord::RecordInvalid)

      existing.reload
      expect(existing).to be_confidential
      expect(existing.redirect_uri).to eq('http://www.memverse.com/api/o2c.html')
    end
  end

  it 'replaces the default callback with MEMVERSE_SWAGGER_REDIRECT_URIS' do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MEMVERSE_SWAGGER_REDIRECT_URIS', anything)
                                 .and_return('https://staging.memverse.com/api/o2c.html')

    expect(described_class.ensure!.redirect_uri.split).to eq(['https://staging.memverse.com/api/o2c.html'])
  end
end

RSpec.describe 'Swagger UI authorization code + PKCE flow', type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:callback) { 'https://www.memverse.com/api/o2c.html' }
  let(:verifier) { 'swagger-ui-pkce-verifier-with-at-least-43-characters' }
  let(:challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) }

  it 'completes once the client has been reconciled' do
    SwaggerOauthApplication.ensure!
    sign_in user

    get '/oauth/authorize', params: {
      response_type: 'code', client_id: SwaggerOauthApplication::UID, redirect_uri: callback,
      scope: 'public', state: '0.42', code_challenge: challenge, code_challenge_method: 'S256'
    }

    expect(response).to have_http_status(:found)
    expect(response.location).to start_with("#{callback}?code=")
    code = Rack::Utils.parse_query(URI.parse(response.location).query).fetch('code')

    post '/oauth/token', params: {
      grant_type: 'authorization_code', client_id: SwaggerOauthApplication::UID,
      code: code, redirect_uri: callback, code_verifier: verifier
    }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('access_token', 'refresh_token')
  end
end
