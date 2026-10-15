# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User registration', type: :request do
  let(:user_params) do
    { name: 'New Member', email: 'new.member@example.com', password: 'please', password_confirmation: 'please' }
  end

  def sign_up(overrides = {})
    post user_registration_path, params: { user: user_params.merge(overrides) }
  end

  it 'tells the user a confirmation email is on its way' do
    sign_up

    expect(response).to be_redirect
    expect(flash[:notice]).to eq(I18n.t('devise.registrations.signed_up_but_unconfirmed'))
    expect(flash[:alert]).to be_nil
  end

  # MEMVERSE-9F
  context 'when Postmark refuses to send the confirmation email' do
    before { stub_mail_delivery_failure(postmark_inactive_recipient_error(user_params[:email])) }

    it 'creates the account and redirects instead of returning a 500' do
      expect { sign_up }.to change(User, :count).by(1)
      expect(response).to be_redirect
    end

    it 'warns the user that the confirmation email could not be sent' do
      sign_up

      expect(flash[:notice]).to be_nil
      expect(flash[:alert]).to eq(I18n.t('devise.registrations.signed_up_but_email_undeliverable'))
    end
  end

  # MEMVERSE-9M
  context 'with a name longer than the login column' do
    it 'creates the account with a login that fits the column' do
      expect { sign_up(name: 'Bartholomew Maximilian Montgomery-Fitzgerald, of Westminster') }
        .to change(User, :count).by(1)

      expect(response).to be_redirect
      expect(User.find_by(email: user_params[:email]).login.length).to eq(User::LOGIN_MAX_LENGTH)
    end
  end
end
