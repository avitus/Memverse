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

    it 'calls AdminMailer.forum_review.deliver in one chain' do
      expect(AdminMailer).to receive(:forum_review).and_return(mail_double)
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
      it 'calls AdminMailer.forum_review which handles all email logic' do
        # This test focuses on the worker's responsibility - calling AdminMailer
        # The AdminMailer itself should be tested separately for email content
        expect(AdminMailer).to receive(:forum_review).and_return(mail_double)
        worker.perform
      end
    end

    describe 'worker configuration' do
      it 'includes Thredded::UrlsHelper' do
        expect(described_class).to include(Thredded::UrlsHelper)
      end

      it 'has retry disabled to prevent log flooding' do
        expect(described_class.sidekiq_options['retry']).to eq(false)
      end

      it 'is configured to run on the high queue' do
        expect(described_class.sidekiq_options['queue']).to eq(:high)
      end
    end

    describe 'method delegation' do
      it 'does not perform any filtering or logic, just delegates to AdminMailer' do
        # Ensure the worker doesn't call any other methods
        expect(worker).not_to receive(:filter_posts)
        expect(worker).not_to receive(:check_conditions)
        expect(worker).not_to receive(:log_activity)
        
        worker.perform
      end
    end
  end

  describe 'scheduled execution' do
    it 'is designed to run as a daily scheduled job' do
      # This is more of a documentation test - the actual scheduling 
      # would be configured in sidekiq-cron or similar
      expect(worker).to respond_to(:perform)
      expect(worker.method(:perform).arity).to eq(0)
    end
  end
end