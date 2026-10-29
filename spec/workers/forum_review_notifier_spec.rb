require 'spec_helper'

RSpec.describe ForumReviewNotifier, type: :worker do
  let(:worker) { described_class.new }
  let(:perform_args) { [] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a non-retryable worker'
  include_examples 'a worker with specific queue', :high

  describe '#perform' do
    let(:mail_double) { double('mail', deliver: true) }

    before do
      # Mock AdminMailer to avoid actual email sending
      allow(AdminMailer).to receive(:forum_review).and_return(mail_double)
    end

    it 'calls AdminMailer.forum_review' do
      expect(AdminMailer).to receive(:forum_review).and_return(mail_double)
      worker.perform
    end

    it 'delivers the forum review email' do
      expect(mail_double).to receive(:deliver)
      worker.perform
    end

    context 'when AdminMailer raises an error' do
      it 'does not handle the error (allows it to propagate)' do
        allow(AdminMailer).to receive(:forum_review).and_raise(StandardError, 'Email service down')
        
        expect { worker.perform }.to raise_error(StandardError, 'Email service down')
      end
    end

    context 'when mail delivery fails' do
      it 'does not handle the error (allows it to propagate)' do
        allow(mail_double).to receive(:deliver).and_raise(Net::SMTPAuthenticationError, 'Authentication failed')
        
        expect { worker.perform }.to raise_error(Net::SMTPAuthenticationError, 'Authentication failed')
      end
    end

    describe 'integration with AdminMailer' do
    end

    describe 'worker configuration' do
    end

    describe 'method delegation' do
    end
  end

  describe 'scheduled execution' do
  end
end