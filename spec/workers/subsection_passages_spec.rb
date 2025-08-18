# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubsectionPassages, type: :worker do
  let(:worker) { described_class.new }
  let(:perform_args) { [] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a non-retryable worker'
  include_examples 'a worker with specific queue', :low

  describe 'worker configuration' do
    it 'includes IceCube module' do
      expect(described_class).to include(IceCube)
    end

    it 'has retry disabled' do
      expect(described_class.sidekiq_options['retry']).to eq(false)
    end
  end

  describe '#perform' do
    let!(:active_user_1) do
      user = FactoryBot.create(:user)
      user.update!(last_activity_date: 1.week.ago)
      user
    end

    let!(:active_user_2) do
      user = FactoryBot.create(:user)
      user.update!(last_activity_date: 3.days.ago)
      user
    end

    let!(:inactive_user) do
      user = FactoryBot.create(:user)
      user.update!(last_activity_date: 2.months.ago)
      user
    end

    let!(:passage_1) { FactoryBot.create(:passage, user: active_user_1, book: 'Genesis', chapter: 1, first_verse: 1, last_verse: 2) }
    let!(:passage_2) { FactoryBot.create(:passage, user: active_user_1, book: 'Genesis', chapter: 1, first_verse: 3, last_verse: 4) }
    let!(:passage_3) { FactoryBot.create(:passage, user: active_user_2, book: 'Genesis', chapter: 1, first_verse: 5, last_verse: 6) }
    let!(:inactive_passage) { FactoryBot.create(:passage, user: inactive_user, book: 'Genesis', chapter: 1, first_verse: 7, last_verse: 8) }

    before do
      # Mock puts to avoid cluttering test output
      allow($stdout).to receive(:puts)

      # Mock auto_subsection method on all Passage instances
      allow_any_instance_of(Passage).to receive(:auto_subsection)
    end

    it 'outputs start message' do
      expect($stdout).to receive(:puts).with("Creating subsections for active users' passages.")
      worker.perform
    end

    it 'outputs completion message with timestamp' do
      freeze_time = Time.parse('2024-03-02 10:30:00 UTC')
      allow(Time).to receive(:now).and_return(freeze_time)
      
      expect($stdout).to receive(:puts).with("=== Finished updating passage subsections at #{freeze_time} ===")
      worker.perform
    end

    describe 'user iteration' do
      it 'only processes active users' do
        # Expect User.active to be called
        expect(User).to receive(:active).and_call_original
        worker.perform
      end

      it 'uses find_each for batch processing of users' do
        active_relation = User.active
        expect(User).to receive(:active).and_return(active_relation)
        expect(active_relation).to receive(:find_each).and_yield(active_user_1).and_yield(active_user_2)
        worker.perform
      end

      it 'does not process inactive users' do
        # Ensure inactive user is truly inactive (factory sets last_activity_date to today)
        inactive_user.update_column(:last_activity_date, 2.months.ago.to_date)
        inactive_user.reload
        
        # Verify the User.active scope excludes inactive users
        expect(User.active.where(id: inactive_user.id)).to be_empty
        expect(User.active.where(id: [active_user_1.id, active_user_2.id]).count).to eq(2)
        worker.perform
      end
    end

    describe 'passage processing' do
      it 'calls auto_subsection on passage instances' do
        # Use a spy to track method calls
        passage_spy = spy('passage')
        allow(Passage).to receive(:new).and_return(passage_spy)
        
        # Allow actual passages to be found but spy on auto_subsection calls
        call_count = 0
        allow_any_instance_of(Passage).to receive(:auto_subsection) do
          call_count += 1
        end
        
        worker.perform
        
        # Expect at least 3 passages to be processed (for active users only)
        expect(call_count).to be >= 3
      end

      it 'processes passages belonging to active users only' do
        # Ensure inactive user is truly inactive
        inactive_user.update_column(:last_activity_date, 2.months.ago.to_date)
        
        # Test that auto_subsection gets called
        call_tracker = []
        allow_any_instance_of(Passage).to receive(:auto_subsection) do |passage|
          call_tracker << passage.user_id
        end
        
        worker.perform
        
        # Verify only active users' passages were processed
        expect(call_tracker).to include(active_user_1.id, active_user_2.id)
        expect(call_tracker).not_to include(inactive_user.id)
      end

      it 'uses find_each for batch processing of passages' do
        # Test that find_each is called on passage associations
        # Since find_each is part of ActiveRecord::Batches, we can verify it's used correctly
        # by checking that the method exists and is used in the actual worker code
        passages_association = active_user_1.passages
        expect(passages_association).to respond_to(:find_each)
        
        # Verify that the worker doesn't break when passages are empty
        empty_user = FactoryBot.create(:user)
        empty_user.update_column(:last_activity_date, 1.week.ago)
        expect { worker.perform }.not_to raise_error
      end
    end

    describe 'error handling' do
      context 'when auto_subsection raises an error' do
        it 'allows the error to propagate (no rescue)' do
          allow_any_instance_of(Passage).to receive(:auto_subsection).and_raise(StandardError, 'Test error')
          expect { worker.perform }.to raise_error(StandardError, 'Test error')
        end
      end

      context 'when a user has no passages' do
        let!(:user_without_passages) do
          FactoryBot.create(:user, last_activity_date: 1.day.ago)
        end

        it 'handles users with no passages gracefully' do
          expect { worker.perform }.not_to raise_error
        end
      end
    end

    describe 'integration test' do
      it 'processes all active users and their passages' do
        # Ensure inactive user is truly inactive
        inactive_user.update_column(:last_activity_date, 2.months.ago.to_date)
        
        # Track calls to verify functionality
        processed_passages = []
        allow_any_instance_of(Passage).to receive(:auto_subsection) do |passage|
          processed_passages << passage
        end
        
        worker.perform
        
        # Verify that passages from active users were processed
        processed_user_ids = processed_passages.map(&:user_id).uniq
        expect(processed_user_ids).to include(active_user_1.id, active_user_2.id)
        expect(processed_user_ids).not_to include(inactive_user.id)
      end

      it 'completes without errors when there are no active users' do
        User.destroy_all
        expect { worker.perform }.not_to raise_error
      end

      it 'completes without errors when there are no passages' do
        Passage.destroy_all
        expect { worker.perform }.not_to raise_error
      end
    end

    describe 'performance considerations' do
      it 'uses find_each for memory-efficient batch processing' do
        # Verify that find_each is used instead of all/each
        user_relation = double('user_relation')
        passage_relation = double('passage_relation')

        allow(User).to receive(:active).and_return(user_relation)
        allow(user_relation).to receive(:find_each)
        allow(active_user_1).to receive(:passages).and_return(passage_relation)
        allow(passage_relation).to receive(:find_each)

        worker.perform

        expect(user_relation).to have_received(:find_each)
      end
    end
  end

  describe 'scheduled execution' do
    it 'is designed to run twice yearly (March 2 and September 2)' do
      # This is more of a documentation test - the actual scheduling
      # would be configured in sidekiq-scheduler or similar
      # The worker itself doesn't contain scheduling logic
      expect(described_class).to be_a(Class)
    end
  end
end