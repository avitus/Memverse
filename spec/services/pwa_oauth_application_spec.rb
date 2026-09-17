require 'rails_helper'

RSpec.describe PwaOauthApplication do
  it 'idempotently provisions the public PWA client with deterministic settings' do
    first_application = described_class.ensure!
    second_application = described_class.ensure!

    expect(second_application.id).to eq(first_application.id)
    expect(second_application.uid).to eq('memverse-pwa')
    expect(second_application).not_to be_confidential
    expect(second_application.scopes.to_s).to eq('public read write')
    expect(second_application.redirect_uri.split).to contain_exactly(
      'https://avitus.github.io/Memverse/authentication/login-callback',
      'http://localhost:5078/authentication/login-callback'
    )
  end
end
