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
        # update_tags returns save's result, so a saved verse answers true
        allow(verse1).to receive(:update_tags).and_return(true)
        allow(verse2).to receive(:update_tags).and_return(true)
        allow(verse3).to receive(:update_tags).and_return(true)

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
    end

    describe 'logging behavior' do
      before do
        allow(Verse).to receive(:find_each)
        allow(ActsAsTaggableOn::Tagging).to receive(:where).and_return(double(delete_all: true))
      end

      it 'logs the start and the completion of the refresh' do
        expect(Sidekiq.logger).to receive(:info).with(/=== Refreshing tag cloud at/).ordered
        expect(Sidekiq.logger).to receive(:info).with(/=== Completed refresh at/).ordered
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
      it 'keeps the previous tag cloud when a verse fails part-way through the rebuild' do
        verse1 = FactoryBot.create(:verse, book: 'John', chapter: 3, versenum: 16)
        verse2 = FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 28)
        verse2.tag_list = ['faith', 'promise']
        verse2.save!
        taggings = ActsAsTaggableOn::Tagging.where(taggable_type: 'Verse')
        expect(taggings.count).to eq(2)

        # Mock first verse to fail, second to succeed
        allow(verse1).to receive(:update_tags).and_raise(StandardError, 'Tag update failed')
        allow(verse2).to receive(:update_tags).and_return(true)

        allow(Verse).to receive(:find_each) do |&block|
          [verse1, verse2].each(&block)
        end

        expect { worker.perform }.to raise_error(StandardError, 'Tag update failed')
        expect(taggings.count).to eq(2)
      end

      it 'skips a verse that does not save, warns about it, and still rebuilds the others' do
        verse1 = FactoryBot.create(:verse, book: 'John', chapter: 3, versenum: 16)
        verse2 = FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 28)

        allow(verse1).to receive(:update_tags).and_return(false) # Verse#update_tags returns save's false
        allow(verse2).to receive(:update_tags).and_return(true)
        allow(Verse).to receive(:find_each) do |&block|
          [verse1, verse2].each(&block)
        end

        expect(Sidekiq.logger).to receive(:warn).with(/skipped 1 verse\(s\) that did not save: #{verse1.id}/)
        expect { worker.perform }.not_to raise_error
        expect(verse2).to have_received(:update_tags)
      end

      it 'handles empty verse collection gracefully' do
        allow(Verse).to receive(:find_each) # yields nothing

        expect { worker.perform }.not_to raise_error
      end
    end

    describe 'worker configuration' do
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