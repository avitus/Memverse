# frozen_string_literal: true

require 'rails_helper'

# MEMVERSE-9F: Devise sends its mail from after_commit callbacks, so a Postmark
# rejection used to escape from User#save and turn a signup into a 500 after the
# account row had already been written.
RSpec.describe User, 'Devise notifications Postmark refuses to deliver' do
  let(:address) { 'suppressed@example.com' }
  let(:attrs) do
    { name: 'Suppressed Address', email: address, password: 'please', password_confirmation: 'please' }
  end

  before { ActionMailer::Base.deliveries.clear }

  context 'when delivery succeeds' do
    it 'sends the confirmation email' do
      User.create!(attrs)

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[address]])
    end

    it 'records no undelivered notification' do
      expect(User.create!(attrs).undelivered_devise_notification).to be_nil
    end
  end

  context 'when Postmark has the recipient on its inactive list' do
    before { stub_mail_delivery_failure(postmark_inactive_recipient_error(address)) }

    it 'still creates the user' do
      expect { User.create!(attrs) }.to change(User, :count).by(1)
    end

    it 'records that the confirmation email was not delivered' do
      expect(User.create!(attrs).undelivered_devise_notification).to eq(:confirmation_instructions)
    end

    it 'does not report the expected suppression to Sentry' do
      allow(Sentry).to receive(:capture_exception)

      User.create!(attrs)

      expect(Sentry).not_to have_received(:capture_exception)
    end

    it 'does not raise when sending password reset instructions' do
      user = FactoryBot.create(:user, email: address)

      expect { user.send_reset_password_instructions }.not_to raise_error
      expect(user.undelivered_devise_notification).to eq(:reset_password_instructions)
    end
  end

  context 'when Postmark rejects the message as an invalid request' do
    let(:error) { postmark_invalid_email_request_error('suppressed@example') }

    before { stub_mail_delivery_failure(error) }

    it 'still creates the user' do
      expect { User.create!(attrs) }.to change(User, :count).by(1)
    end

    it 'records that the confirmation email was not delivered' do
      expect(User.create!(attrs).undelivered_devise_notification).to eq(:confirmation_instructions)
    end

    it 'reports it to Sentry as a warning, since a misconfigured message also lands here' do
      allow(Sentry).to receive(:capture_exception)

      User.create!(attrs)

      expect(Sentry).to have_received(:capture_exception).with(error, level: :warning)
    end
  end

  context 'when Postmark fails for a reason unrelated to the recipient' do
    before { stub_mail_delivery_failure(Postmark::InvalidApiKeyError.new(401, '{}', {})) }

    it 'lets the error propagate' do
      expect { User.create!(attrs) }.to raise_error(Postmark::InvalidApiKeyError)
    end
  end
end
