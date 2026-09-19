require 'rails_helper'

RSpec.describe 'CORS policy', type: :request do
  let(:allowed_origin) { 'https://avitus.github.io' }

  it 'allows actual API responses from a configured origin' do
    get '/api/v1/me', headers: { 'Origin' => allowed_origin }

    expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
    expect(response.headers['Vary']).to include('Origin')
  end

  it 'allows actual OAuth token responses from a configured origin' do
    post '/oauth/token',
         params: {},
         headers: { 'Origin' => allowed_origin }

    expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
  end

  it 'allows the local PWA origin' do
    get '/api/v1/me', headers: { 'Origin' => 'http://localhost:5078' }

    expect(response.headers['Access-Control-Allow-Origin']).to eq('http://localhost:5078')
  end

  it 'allows public-client token revocation from the hosted PWA' do
    options '/oauth/revoke',
            headers: {
              'Origin' => allowed_origin,
              'Access-Control-Request-Method' => 'POST',
              'Access-Control-Request-Headers' => 'Content-Type'
            }

    expect(response).to have_http_status(:ok)
    expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
    expect(response.headers['Access-Control-Allow-Methods']).to include('POST', 'OPTIONS')
  end

  it 'answers API preflight requests with the configured methods and headers' do
    options '/api/v1/me',
            headers: {
              'Origin' => allowed_origin,
              'Access-Control-Request-Method' => 'PATCH',
              'Access-Control-Request-Headers' => 'Authorization, Content-Type'
            }

    expect(response).to have_http_status(:ok)
    expect(response.headers['Access-Control-Allow-Origin']).to eq(allowed_origin)
    expect(response.headers['Access-Control-Allow-Methods']).to include(
      'GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'
    )
    expect(response.headers['Access-Control-Allow-Headers']).to include(
      'Authorization', 'Content-Type'
    )
  end

  it 'does not allow an unconfigured origin' do
    options '/api/v1/me',
            headers: {
              'Origin' => 'https://unconfigured.example',
              'Access-Control-Request-Method' => 'GET'
            }

    expect(response.headers).not_to include('Access-Control-Allow-Origin')
  end
end
