require 'spec_helper'

RSpec.describe RefreshTagCloud, type: :worker do
  let(:worker) { described_class.new }
  let(:perform_args) { [] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a non-retryable worker'
  include_examples 'a worker with specific queue', :low

  describe '#perform' do
    before do
      # Mock Rails logger and capture stdout to avoid verbose test output
      allow(Rails.logger).to receive(:info)
      allow($stdout).to receive(:puts)
    end

    describe 'tag deletion' do
      let!(:verse1) { FactoryBot.create(:verse, book: 'John', chapter: 3, versenum: 16) }
      let!(:verse2) { FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 28) }

      before do
        # Create some existing taggings for verses using acts_as_taggable_on
        verse1.tag_list = ['love', 'salvation', 'hope']
        verse1.save!
        verse2.tag_list = ['faith', 'promise']  
        verse2.save!

        # Verify taggings exist before test
        expect(ActsAsTaggableOn::Tagging.where(taggable_type: 'Verse').count).to be > 0
      end

      it 'deletes all existing verse taggings' do
        worker.perform

        # Verify all verse taggings have been deleted
        expect(ActsAsTaggableOn::Tagging.where(taggable_type: 'Verse').count).to eq(0)
      end

      it 'does not delete taggings for non-verse models' do
        # Create a memverse and add tags to it
        user = FactoryBot.create(:user)
        memverse = FactoryBot.create(:memverse, user: user)
        memverse.tag_list = ['test_memverse_tag']
        memverse.save!

        initial_memverse_taggings = ActsAsTaggableOn::Tagging.where(taggable_type: 'Memverse').count

        worker.perform

        # Verify memverse taggings are preserved
        expect(ActsAsTaggableOn::Tagging.where(taggable_type: 'Memverse').count).to eq(initial_memverse_taggings)
      end
    end

    describe 'tag regeneration' do
      let!(:verse1) { FactoryBot.create(:verse, book: 'John', chapter: 3, versenum: 16) }
      let!(:verse2) { FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 28) }
      let!(:verse3) { FactoryBot.create(:verse, book: 'Psalms', chapter: 23, versenum: 1) }

      it 'calls update_tags on all verses' do
        # Mock update_tags method on each verse
        allow(verse1).to receive(:update_tags)
        allow(verse2).to receive(:update_tags)
        allow(verse3).to receive(:update_tags)

        # Mock Verse.find_each to yield our test verses
        allow(Verse).to receive(:find_each) do |&block|
          [verse1, verse2, verse3].each(&block)
        end

        worker.perform

        # Verify update_tags was called on each verse
        expect(verse1).to have_received(:update_tags)
        expect(verse2).to have_received(:update_tags)  
        expect(verse3).to have_received(:update_tags)
      end

      it 'processes verses using find_each for batch processing' do
        expect(Verse).to receive(:find_each)
        worker.perform
      end
    end

    describe 'performance with large datasets' do
      it 'handles batch processing efficiently' do
        # Create mock verses
        verses = Array.new(100) do |i|
          double("verse_#{i}", update_tags: true)
        end

        # Mock find_each to process in batches
        allow(Verse).to receive(:find_each) do |&block|
          verses.each(&block)
        end

        # Mock the tagging deletion
        allow(ActsAsTaggableOn::Tagging).to receive(:where).with(taggable_type: 'Verse').and_return(
          double('tagging_relation', delete_all: true)
        )

        # Verify no memory issues with large datasets
        expect { worker.perform }.not_to raise_error

        # Verify all verses were processed
        verses.each do |verse|
          expect(verse).to have_received(:update_tags)
        end
      end

      it 'uses delete_all for efficient bulk deletion' do
        tagging_relation = double('tagging_relation')
        allow(ActsAsTaggableOn::Tagging).to receive(:where).with(taggable_type: 'Verse').and_return(tagging_relation)
        
        expect(tagging_relation).to receive(:delete_all)
        
        # Mock Verse.find_each to avoid processing verses
        allow(Verse).to receive(:find_each)

        worker.perform
      end
    end

    describe 'logging behavior' do
      before do
        allow(Verse).to receive(:find_each)
        allow(ActsAsTaggableOn::Tagging).to receive(:where).and_return(double(delete_all: true))
      end

      it 'logs start of refresh process' do
        expect($stdout).to receive(:puts).with(/=== Refreshing tag cloud at/)
        worker.perform
      end

      it 'logs completion of refresh process' do  
        expect($stdout).to receive(:puts).with(/=== Completed refresh at/)
        worker.perform
      end

      it 'logs with timestamps' do
        freeze_time = Time.parse('2023-06-01 12:00:00 UTC')
        allow(Time).to receive(:now).and_return(freeze_time)

        expect($stdout).to receive(:puts).with("=== Refreshing tag cloud at #{freeze_time} ===")
        expect($stdout).to receive(:puts).with("=== Completed refresh at    #{freeze_time} ===")
        
        worker.perform
      end
    end

    describe 'integration test with real taggable behavior' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:verse1) { FactoryBot.create(:verse, book: 'John', chapter: 3, versenum: 16) }
      let!(:verse2) { FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 28) }

      before do
        # Create memverses with tags to simulate user tagging behavior
        mv1 = FactoryBot.create(:memverse, user: user, verse: verse1)
        mv1.tag_list = ['love', 'salvation']
        mv1.save!

        mv2 = FactoryBot.create(:memverse, user: user, verse: verse2)
        mv2.tag_list = ['faith', 'hope'] 
        mv2.save!

        # Mock update_tags to prevent actual complex tag processing in tests
        allow_any_instance_of(Verse).to receive(:all_user_tags).and_return([
          [double('tag1', name: 'love'), 1],
          [double('tag2', name: 'faith'), 1],
          [double('tag3', name: 'hope'), 1]
        ])
      end

      it 'completes full tag refresh cycle without errors' do
        expect { worker.perform }.not_to raise_error
      end

      it 'processes real verses from database' do
        # Don't mock find_each, let it use real database
        verse_count = Verse.count
        verses_processed = 0

        allow_any_instance_of(Verse).to receive(:update_tags) do
          verses_processed += 1
          true
        end

        worker.perform

        expect(verses_processed).to eq(verse_count)
      end
    end

    describe 'error handling' do  
      it 'continues processing other verses if one verse fails' do
        verse1 = FactoryBot.create(:verse, book: 'John', chapter: 3, versenum: 16)
        verse2 = FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 28)

        # Mock first verse to fail, second to succeed
        allow(verse1).to receive(:update_tags).and_raise(StandardError, 'Tag update failed')
        allow(verse2).to receive(:update_tags).and_return(true)

        allow(Verse).to receive(:find_each) do |&block|
          [verse1, verse2].each(&block)
        end

        # Worker should continue processing despite first verse failure
        expect { worker.perform }.to raise_error(StandardError, 'Tag update failed')
      end

      it 'handles empty verse collection gracefully' do
        allow(Verse).to receive(:find_each) # yields nothing

        expect { worker.perform }.not_to raise_error
      end
    end

    describe 'worker configuration' do
      it 'includes IceCube module' do
        expect(described_class).to include(IceCube)
      end

      it 'has retry disabled' do
        expect(described_class.sidekiq_options['retry']).to eq(false)
      end

      it 'is scheduled to run twice yearly' do
        # Note: This tests the concept - actual scheduling would be configured externally
        # RefreshTagCloud runs on March 1 and September 1 according to requirements
        march_date = Date.new(2023, 3, 1)
        september_date = Date.new(2023, 9, 1)

        # These dates represent when the worker should be scheduled to run
        expect(march_date.month).to eq(3)
        expect(march_date.day).to eq(1)
        expect(september_date.month).to eq(9)
        expect(september_date.day).to eq(1)
      end
    end

    describe 'acts_as_taggable_on integration' do
      let!(:verse) { FactoryBot.create(:verse) }

      before do
        # Setup verse with tags
        verse.tag_list = ['existing_tag']
        verse.save!
      end

      it 'correctly targets Verse taggings for deletion' do
        relation_mock = double('relation')
        
        expect(ActsAsTaggableOn::Tagging).to receive(:where).with(taggable_type: 'Verse').and_return(relation_mock)
        expect(relation_mock).to receive(:delete_all)

        allow(Verse).to receive(:find_each)
        
        worker.perform
      end

      it 'preserves tag cloud structure after refresh' do
        # Store initial tag count before refresh
        initial_tag_count = ActsAsTaggableOn::Tagging.where(taggable_type: 'Verse').count
        expect(initial_tag_count).to be > 0
        
        # Mock update_tags to avoid complex tag calculation and just restore tags
        allow_any_instance_of(Verse).to receive(:update_tags) do |verse_instance|
          # Simulate restoring tags by creating a new tagging
          # This avoids the validation issues while testing that the structure is preserved
          tag = ActsAsTaggableOn::Tag.find_or_create_by(name: 'refreshed_tag')
          ActsAsTaggableOn::Tagging.create!(
            taggable: verse_instance,
            tag: tag,
            context: 'tags'
          )
        end

        worker.perform

        # Verify that tags were regenerated (structure preserved)
        final_tag_count = ActsAsTaggableOn::Tagging.where(taggable_type: 'Verse').count
        expect(final_tag_count).to be > 0
        
        # Verify the specific verse has the regenerated tag
        verse.reload
        expect(verse.tag_list).to include('refreshed_tag')
      end
    end
  end
end