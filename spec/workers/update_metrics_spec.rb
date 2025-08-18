require 'spec_helper'

RSpec.describe UpdateMetrics, type: :worker do
  let(:worker) { described_class.new }
  let(:perform_args) { [] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a retryable worker'
  include_examples 'a worker with specific queue', :default

  describe '#perform' do
    before do
      # Mock DailyStats.update to avoid database operations
      allow(DailyStats).to receive(:update)
    end

    it 'calls DailyStats.update' do
      worker.perform
      expect(DailyStats).to have_received(:update).once
    end

    context 'when DailyStats.update succeeds' do
      it 'completes without error' do
        expect { worker.perform }.not_to raise_error
      end
    end

    context 'when DailyStats.update raises an error' do
      let(:error_message) { 'Database connection failed' }

      before do
        allow(DailyStats).to receive(:update).and_raise(StandardError.new(error_message))
      end

      it 'allows the error to bubble up for Sidekiq retry handling' do
        expect { worker.perform }.to raise_error(StandardError, error_message)
      end
    end

    context 'when DailyStats.update raises a database error' do
      before do
        allow(DailyStats).to receive(:update).and_raise(ActiveRecord::ConnectionTimeoutError)
      end

      it 'allows database errors to bubble up for retry' do
        expect { worker.perform }.to raise_error(ActiveRecord::ConnectionTimeoutError)
      end
    end
  end

  describe 'Sidekiq configuration' do
    it 'has retry enabled' do
      expect(described_class.sidekiq_options['retry']).to eq(true)
    end

    it 'uses the default queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:default)
    end
  end

  describe 'integration with DailyStats' do
    let(:today) { Date.today }

    before do
      # Allow real DailyStats.update for integration testing
      allow(DailyStats).to receive(:update).and_call_original
      
      # Mock the database queries that DailyStats.update performs
      allow(DailyStats).to receive(:where).with("entry_date = ?", today).and_return(double(exists?: false))
      allow(User).to receive(:count).and_return(100)
      allow(User).to receive(:active).and_return(double(count: 50))
      allow(User).to receive(:american).and_return(double(count: 75, active: double(count: 30)))
      allow(Verse).to receive(:count).and_return(1000)
      allow(Memverse).to receive(:count).and_return(2000)
      allow(Memverse).to receive(:memorized).and_return(double(count: 800, current: double(count: 700)))
      allow(Memverse).to receive(:learning).and_return(double(count: 1200, current: double(count: 1000)))
      allow(Memverse).to receive(:american).and_return(
        double(
          count: 1500,
          memorized: double(count: 600, current: double(count: 500)),
          learning: double(count: 900, current: double(count: 800))
        )
      )
      
      # Mock DailyStats creation and saving
      daily_stats_global = instance_double(DailyStats, save: true)
      daily_stats_us = instance_double(DailyStats, save: true)
      
      allow(DailyStats).to receive(:new).and_return(daily_stats_global, daily_stats_us)
      allow(daily_stats_global).to receive(:entry_date=)
      allow(daily_stats_global).to receive(:users=)
      allow(daily_stats_global).to receive(:users_active_in_month=)
      allow(daily_stats_global).to receive(:verses=)
      allow(daily_stats_global).to receive(:memverses=)
      allow(daily_stats_global).to receive(:memverses_memorized=)
      allow(daily_stats_global).to receive(:memverses_learning=)
      allow(daily_stats_global).to receive(:memverses_memorized_not_overdue=)
      allow(daily_stats_global).to receive(:memverses_learning_active_in_month=)
      
      allow(daily_stats_us).to receive(:segment=)
      allow(daily_stats_us).to receive(:entry_date=)
      allow(daily_stats_us).to receive(:users=)
      allow(daily_stats_us).to receive(:users_active_in_month=)
      allow(daily_stats_us).to receive(:verses=)
      allow(daily_stats_us).to receive(:memverses=)
      allow(daily_stats_us).to receive(:memverses_memorized=)
      allow(daily_stats_us).to receive(:memverses_learning=)
      allow(daily_stats_us).to receive(:memverses_memorized_not_overdue=)
      allow(daily_stats_us).to receive(:memverses_learning_active_in_month=)
    end

    it 'successfully triggers daily stats update process' do
      expect { worker.perform }.not_to raise_error
      expect(DailyStats).to have_received(:update).once
    end
  end

  describe 'error handling and retry behavior' do
    context 'with various error types that should trigger retry' do
      [
        ActiveRecord::ConnectionTimeoutError,
        ActiveRecord::StatementInvalid,
        StandardError,
        RuntimeError
      ].each do |error_class|
        context "when #{error_class} is raised" do
          before do
            allow(DailyStats).to receive(:update).and_raise(error_class.new("Test error"))
          end

          it "allows #{error_class} to bubble up for Sidekiq retry" do
            expect { worker.perform }.to raise_error(error_class)
          end
        end
      end
    end
  end

  describe 'scheduling integration' do
    it 'can be enqueued for execution' do
      # This worker is typically scheduled to run daily at noon
      # This test verifies the worker can be enqueued properly
      expect(described_class).to respond_to(:perform_async)
    end

    it 'has no arguments in its perform method' do
      method = described_class.instance_method(:perform)
      expect(method.arity).to eq(0)
    end
  end
end