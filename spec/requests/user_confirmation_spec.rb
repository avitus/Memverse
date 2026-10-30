# frozen_string_literal: true

require 'rails_helper'

# Devise's ConfirmationsController#show confirms the account from the emailed
# token; User's after_update callback (recently_activated?) then sends the one
# activation (welcome) email.
RSpec.describe 'Account confirmation', type: :request do
  let!(:user) { FactoryBot.create(:user, confirmed_at: nil) }

  def activation_emails
    ActionMailer::Base.deliveries.select { |mail| mail.subject == 'Your Memverse account has been activated!' }
  end

  def confirm_with(token)
    get user_confirmation_path, params: { confirmation_token: token }
  end

  before { ActionMailer::Base.deliveries.clear }

  context 'with the token from the confirmation email' do
    it 'confirms the account' do
      confirm_with(user.confirmation_token)

      expect(response).to be_redirect
      expect(user.reload).to be_confirmed
    end

    it 'sends exactly one activation email to the user' do
      confirm_with(user.confirmation_token)

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(activation_emails.map(&:to)).to eq([[user.email]])
    end

    it 'does not send a second activation email when the link is opened again' do
      confirm_with(user.confirmation_token)
      confirm_with(user.confirmation_token)

      expect(user.reload).to be_confirmed
      expect(activation_emails.size).to eq(1)
    end
  end

  context 'with an invalid token' do
    it 'confirms nothing and sends nothing' do
      confirm_with('not-a-real-token')

      # Devise re-renders the "resend confirmation" form with the error
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Confirmation token is invalid')
      expect(user.reload).not_to be_confirmed
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
