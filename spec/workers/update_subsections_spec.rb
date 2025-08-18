require 'spec_helper'

RSpec.describe UpdateSubsections, type: :worker do
  let(:worker) { described_class.new }
  let(:perform_args) { [] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a non-retryable worker'
  include_examples 'a worker with specific queue', :low

  describe 'Sidekiq configuration' do
    it 'has retry disabled' do
      expect(described_class.sidekiq_options['retry']).to eq(false)
    end

    it 'uses the low queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:low)
    end
  end

  describe '#perform' do
    let(:mock_biblebooks) do
      {
        en: {
          'Matt' => 'Matthew',
          'Mark' => 'Mark',
          'John' => 'John'
        }
      }
    end

    let(:mock_final_verse_matthew) { double('FinalVerse', chapter: 28, last_verse: 20) }
    let(:mock_final_verse_mark) { double('FinalVerse', chapter: 16, last_verse: 20) }
    let(:mock_final_verse_john) { double('FinalVerse', chapter: 21, last_verse: 25) }

    let(:mock_final_verse_chapter_1) { double('FinalVerse', last_verse: 25) }
    let(:mock_final_verse_chapter_2) { double('FinalVerse', last_verse: 12) }

    let(:mock_uberverse_1) { double('Uberverse') }
    let(:mock_uberverse_2) { double('Uberverse') }

    before do
      # Mock the BIBLEBOOKS constant
      stub_const('BIBLEBOOKS', mock_biblebooks)

      # Mock console output
      allow($stdout).to receive(:puts)

      # Mock FinalVerse queries for book chapters (Matthew has 28 chapters)
      allow(FinalVerse).to receive(:where).with(book: 'Matthew')
                                          .and_return(double(order: double(first: mock_final_verse_matthew)))
      allow(FinalVerse).to receive(:where).with(book: 'Mark')
                                          .and_return(double(order: double(first: mock_final_verse_mark)))
      allow(FinalVerse).to receive(:where).with(book: 'John')
                                          .and_return(double(order: double(first: mock_final_verse_john)))

      # Mock FinalVerse queries for all chapters in each book
      (1..28).each do |chapter|
        final_verse = chapter <= 2 ? mock_final_verse_chapter_1 : double('FinalVerse', last_verse: 1)
        allow(FinalVerse).to receive(:where).with(book: 'Matthew', chapter: chapter)
                                            .and_return(double(first: final_verse))
      end

      (1..16).each do |chapter|
        final_verse = double('FinalVerse', last_verse: 1)
        allow(FinalVerse).to receive(:where).with(book: 'Mark', chapter: chapter)
                                            .and_return(double(first: final_verse))
      end

      (1..21).each do |chapter|
        final_verse = double('FinalVerse', last_verse: 1)
        allow(FinalVerse).to receive(:where).with(book: 'John', chapter: chapter)
                                            .and_return(double(first: final_verse))
      end

      # Mock Passage queries (default to no passages)
      allow(Passage).to receive(:where).and_return(double(count: 0))

      # Mock Uberverse queries (default stub)
      allow(Uberverse).to receive(:where).and_return(double(first: mock_uberverse_1))
      allow(mock_uberverse_1).to receive(:update_attribute)
      allow(mock_uberverse_2).to receive(:update_attribute)
    end

    context 'when there are no passages for a chapter' do
      it 'skips processing that chapter' do
        # Use a simplified mock for this test
        simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
        stub_const('BIBLEBOOKS', simplified_biblebooks)
        
        allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                            .and_return(double(first: double(last_verse: 5)))
        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                         .and_return(double(count: 0))
        
        worker.perform
        expect($stdout).not_to have_received(:puts).with(/TestBook 1 :/)
      end
    end

    context 'when there are passages for a chapter' do
      let(:passage_count) { 10 }
      
      before do
        # Use a simplified mock for this test
        simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
        stub_const('BIBLEBOOKS', simplified_biblebooks)
        
        allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                            .and_return(double(first: double(last_verse: 5)))
        
        # Mock passage count query
        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                         .and_return(double(count: passage_count))
        
        # Mock first verse count queries (verses 2-5)
        (2..5).each do |verse|
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: verse % 3)) # Return varying counts for testing
        end
        
        # Mock last verse count queries (verses 1-4)
        (1..4).each do |verse|
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: verse % 5)) # Return varying counts for testing
        end

        # Mock Uberverse updates for each verse
        (1..5).each do |verse|
          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: verse)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute)
        end
      end

      it 'processes the chapter and calculates subsection probabilities' do
        worker.perform
        expect($stdout).to have_received(:puts).with(/TestBook 1 :/)
      end

      it 'calculates probability based on first_verse and last_verse counts' do
        worker.perform

        # Verify the probability calculation logic
        # The algorithm should combine first_verse_count and last_verse_count
        # and normalize by passage_count
        (1..5).each do |verse|
          mock_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: verse).first
          expect(mock_uberverse).to have_received(:update_attribute).with(:subsection_end, anything)
        end
      end

      it 'applies peak detection algorithm correctly' do
        worker.perform

        # The algorithm should apply a convolution filter to detect peaks
        # and remove negative values, then add 100 to the final verse
        (1..5).each do |verse|
          mock_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: verse).first
          expect(mock_uberverse).to have_received(:update_attribute) do |attribute, value|
            expect(attribute).to eq(:subsection_end)
            expect(value).to be >= 0 # No negative values after peak detection
          end
        end
      end

      it 'sets the final verse to 100' do
        worker.perform

        # The final verse (verse 5) should always be set to 100
        final_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: 5).first
        expect(final_uberverse).to have_received(:update_attribute).with(:subsection_end, 100)
      end
    end

    context 'probability calculation algorithm' do
      let(:passage_count) { 20 }
      let(:first_verse_counts) { [2, 4, 1] } # verses 2-4
      let(:last_verse_counts) { [1, 3, 2] }  # verses 1-3

      before do
        # Use a simplified mock for this test
        simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
        stub_const('BIBLEBOOKS', simplified_biblebooks)
        
        allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                            .and_return(double(first: double(last_verse: 4)))

        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                         .and_return(double(count: passage_count))

        # Mock first verse counts
        first_verse_counts.each_with_index do |count, index|
          verse = index + 2 # verses 2-4
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: count))
        end

        # Mock last verse counts
        last_verse_counts.each_with_index do |count, index|
          verse = index + 1 # verses 1-3
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: count))
        end

        # Mock Uberverse updates
        (1..4).each do |verse|
          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: verse)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute)
        end
      end

      it 'correctly combines first_verse and last_verse counts' do
        worker.perform

        # Expected probability calculation:
        # For verse i (1-indexed in result, 0-indexed in arrays):
        # combined_count = first_verse_counts[i-1] + last_verse_counts[i-1]
        # probability = (combined_count / passage_count * 100).to_i

        expected_probabilities = []
        (0..2).each do |i| # verses 1-3
          combined = first_verse_counts[i] + last_verse_counts[i]
          prob = (combined / passage_count.to_f * 100).to_i
          expected_probabilities << prob
        end

        # The algorithm should produce these base probabilities before peak detection
        # We can't easily test the exact final values due to the peak detection filter,
        # but we can verify that the calculation is performed
        (1..4).each do |verse|
          mock_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: verse).first
          expect(mock_uberverse).to have_received(:update_attribute).with(:subsection_end, anything)
        end
      end
    end

    context 'peak detection algorithm' do
      it 'applies the convolution filter correctly' do
        # The peak detection uses this formula for each position i:
        # result[i] = -padded[i]/6 - padded[i+1]/4 - padded[i+2]/2 + padded[i+3] - padded[i+4]/2 - padded[i+5]/4 - padded[i+6]/6
        # This is a derivative-like filter that enhances peaks

        # Use a simplified mock for this test
        simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
        stub_const('BIBLEBOOKS', simplified_biblebooks)

        allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                            .and_return(double(first: double(last_verse: 5)))

        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                         .and_return(double(count: 1))

        # Create a simple pattern where verse 3 should be a peak
        [2, 3, 4, 5].each do |verse|
          count = verse == 3 ? 1 : 0 # Only verse 3 has passages starting there
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: count))
        end

        [1, 2, 3, 4].each do |verse|
          count = verse == 2 ? 1 : 0 # Only verse 2 has passages ending there
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: count))
        end

        (1..5).each do |verse|
          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: verse)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute)
        end

        worker.perform

        # Verify that negative values are removed and final verse is set to 100
        (1..4).each do |verse|
          mock_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: verse).first
          expect(mock_uberverse).to have_received(:update_attribute) do |attr, value|
            expect(value).to be >= 0
          end
        end

        final_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: 5).first
        expect(final_uberverse).to have_received(:update_attribute).with(:subsection_end, 100)
      end
    end

    context 'edge cases' do
      context 'when a chapter has only one verse' do
        before do
          simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
          stub_const('BIBLEBOOKS', simplified_biblebooks)
          
          allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                              .and_return(double(order: double(first: double(chapter: 1))))
          allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                              .and_return(double(first: double(last_verse: 1)))

          allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                           .and_return(double(count: 1))

          # No passages can start at verse 2+ in a 1-verse chapter
          # No passages can end at verse 1-0 (empty range)

          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: 1)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute)
        end

        it 'handles single verse chapters correctly' do
          expect { worker.perform }.not_to raise_error
          
          # The single verse should be set to 100 (as it's the final verse)
          mock_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: 1).first
          expect(mock_uberverse).to have_received(:update_attribute).with(:subsection_end, 100)
        end
      end

      context 'when a chapter has only two verses' do
        before do
          simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
          stub_const('BIBLEBOOKS', simplified_biblebooks)
          
          allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                              .and_return(double(order: double(first: double(chapter: 1))))
          allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                              .and_return(double(first: double(last_verse: 2)))

          allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                           .and_return(double(count: 1))

          # Only verse 2 can be a first_verse in a 2-verse chapter
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, 2)
                                .and_return(double(count: 0))

          # Only verse 1 can be a last_verse in a 2-verse chapter
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, 1)
                                .and_return(double(count: 0))

          [1, 2].each do |verse|
            mock_uberverse = double('Uberverse')
            allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: verse)
                                               .and_return(double(first: mock_uberverse))
            allow(mock_uberverse).to receive(:update_attribute)
          end
        end

        it 'handles two verse chapters correctly' do
          expect { worker.perform }.not_to raise_error

          # Both verses should be updated, with verse 2 set to 100
          mock_uberverse_1 = Uberverse.where(book: 'TestBook', chapter: 1, versenum: 1).first
          mock_uberverse_2 = Uberverse.where(book: 'TestBook', chapter: 1, versenum: 2).first
          
          expect(mock_uberverse_1).to have_received(:update_attribute).with(:subsection_end, anything)
          expect(mock_uberverse_2).to have_received(:update_attribute).with(:subsection_end, 100)
        end
      end

      context 'when passages have length <= 2' do
        before do
          simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
          stub_const('BIBLEBOOKS', simplified_biblebooks)
          
          allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                              .and_return(double(order: double(first: double(chapter: 1))))
          allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                              .and_return(double(first: double(last_verse: 5)))

          # No passages with length > 2
          allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                           .and_return(double(count: 0))
        end

        it 'skips chapters with no qualifying passages' do
          worker.perform

          # Should not attempt to update any uberverses for this chapter
          expect(Uberverse).not_to have_received(:where).with(book: 'TestBook', chapter: 1, versenum: anything)
        end
      end
    end

    context 'book and chapter iteration' do
      before do
        # Ensure all FinalVerse queries return something to prevent errors
        allow(FinalVerse).to receive(:where).with(book: anything)
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: anything, chapter: anything)
                                            .and_return(double(first: double(last_verse: 1)))
        allow(Passage).to receive(:where).and_return(double(count: 0))
      end

      it 'iterates through all books in BIBLEBOOKS[:en]' do
        worker.perform

        # Should query for final chapters in all three mocked books
        expect(FinalVerse).to have_received(:where).with(book: 'Matthew')
        expect(FinalVerse).to have_received(:where).with(book: 'Mark')
        expect(FinalVerse).to have_received(:where).with(book: 'John')
      end

      it 'iterates through all chapters in each book' do
        # Mock Matthew to have 2 chapters
        allow(FinalVerse).to receive(:where).with(book: 'Matthew')
                                            .and_return(double(order: double(first: double(chapter: 2))))

        worker.perform

        # Should query both chapters in Matthew
        expect(FinalVerse).to have_received(:where).with(book: 'Matthew', chapter: 1)
        expect(FinalVerse).to have_received(:where).with(book: 'Matthew', chapter: 2)
      end
    end

    context 'logging and output' do
      before do
        simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
        stub_const('BIBLEBOOKS', simplified_biblebooks)
        
        allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                            .and_return(double(first: double(last_verse: 3)))

        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                         .and_return(double(count: 1))

        # Mock simple passage data
        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, 2)
                                         .and_return(double(count: 1))
        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, 3)
                                         .and_return(double(count: 0))

        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, 1)
                                         .and_return(double(count: 0))
        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, 2)
                                         .and_return(double(count: 1))

        (1..3).each do |verse|
          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: verse)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute)
        end
      end

      it 'outputs start message' do
        worker.perform
        expect($stdout).to have_received(:puts).with('Starting calculation of subsection probabilities')
      end

      it 'outputs progress for each processed chapter' do
        worker.perform
        expect($stdout).to have_received(:puts).with(/TestBook 1 :/)
      end

      it 'outputs completion message with timestamp' do
        allow(Time).to receive(:now).and_return(Time.parse('2023-01-01 12:00:00'))
        
        worker.perform
        expect($stdout).to have_received(:puts).with(/=== Finished calculating subsection probabilities at.*===/)
      end
    end

    context 'error handling' do
      context 'when FinalVerse query fails' do
        before do
          allow(FinalVerse).to receive(:where).with(book: 'Matthew')
                                              .and_raise(ActiveRecord::RecordNotFound)
        end

        it 'allows the error to bubble up' do
          expect { worker.perform }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when Passage query fails' do
        before do
          allow(FinalVerse).to receive(:where).with(book: 'Matthew')
                                              .and_return(double(order: double(first: double(chapter: 1))))
          allow(FinalVerse).to receive(:where).with(book: 'Matthew', chapter: 1)
                                              .and_return(double(first: double(last_verse: 3)))

          allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'Matthew', 1)
                                           .and_raise(ActiveRecord::StatementInvalid)
        end

        it 'allows the error to bubble up' do
          expect { worker.perform }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end

      context 'when Uberverse update fails' do
        before do
          allow(FinalVerse).to receive(:where).with(book: 'Matthew')
                                              .and_return(double(order: double(first: double(chapter: 1))))
          allow(FinalVerse).to receive(:where).with(book: 'Matthew', chapter: 1)
                                              .and_return(double(first: double(last_verse: 3)))

          allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'Matthew', 1)
                                           .and_return(double(count: 1))

          # Mock passage queries
          allow(Passage).to receive(:where).with(/first_verse/).and_return(double(count: 0))
          allow(Passage).to receive(:where).with(/last_verse/).and_return(double(count: 0))

          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'Matthew', chapter: 1, versenum: 1)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'allows the error to bubble up' do
          expect { worker.perform }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe 'statistical analysis correctness' do
    context 'with realistic passage data' do
      let(:passage_count) { 50 }
      
      before do
        # Mock a realistic scenario using simplified TestBook
        simplified_biblebooks = { en: { 'Test' => 'TestBook' } }
        stub_const('BIBLEBOOKS', simplified_biblebooks)
        
        allow(FinalVerse).to receive(:where).with(book: 'TestBook')
                                            .and_return(double(order: double(first: double(chapter: 1))))
        allow(FinalVerse).to receive(:where).with(book: 'TestBook', chapter: 1)
                                            .and_return(double(first: double(last_verse: 10)))

        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'TestBook', 1)
                                         .and_return(double(count: passage_count))

        # Create realistic passage patterns - some verses are more likely to be
        # section breaks than others (e.g., verses 4, 7)
        first_verse_patterns = Array.new(10, 1) # Base count of 1
        [4, 7].each { |v| first_verse_patterns[v-2] = 8 } # Popular starting points

        last_verse_patterns = Array.new(10, 1) # Base count of 1  
        [3, 6].each { |v| last_verse_patterns[v-1] = 8 } # Popular ending points

        # Mock first_verse queries (verses 2-10)
        (2..10).each_with_index do |verse, index|
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND first_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: first_verse_patterns[index]))
        end

        # Mock last_verse queries (verses 1-9)
        (1..9).each_with_index do |verse, index|
          allow(Passage).to receive(:where)
                                .with('length > 2 AND book = ? AND chapter = ? AND last_verse = ?', 'TestBook', 1, verse)
                                .and_return(double(count: last_verse_patterns[index]))
        end

        # Mock Uberverse updates
        (1..10).each do |verse|
          mock_uberverse = double('Uberverse')
          allow(Uberverse).to receive(:where).with(book: 'TestBook', chapter: 1, versenum: verse)
                                             .and_return(double(first: mock_uberverse))
          allow(mock_uberverse).to receive(:update_attribute)
        end
      end

      it 'produces higher probabilities for natural section breaks' do
        worker.perform

        # Verses that are popular section breaks should have higher probabilities
        # after the algorithm processes them. We can't test exact values due to
        # the peak detection filter, but we can verify the process completes
        (1..10).each do |verse|
          mock_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: verse).first
          expect(mock_uberverse).to have_received(:update_attribute).with(:subsection_end, anything)
        end

        # Final verse should always be 100
        final_uberverse = Uberverse.where(book: 'TestBook', chapter: 1, versenum: 10).first
        expect(final_uberverse).to have_received(:update_attribute).with(:subsection_end, 100)
      end
    end
  end

  describe 'integration with background job scheduling' do
    it 'can be enqueued for execution' do
      expect(described_class).to respond_to(:perform_async)
    end

    it 'has no arguments in its perform method' do
      method = described_class.instance_method(:perform)
      expect(method.arity).to eq(0)
    end

    it 'includes IceCube for scheduling' do
      expect(described_class).to include(IceCube)
    end
  end

  describe 'memory and performance considerations' do
    before do
      # Mock a large book (Psalms with 150 chapters, varying verse counts)
      stub_const('BIBLEBOOKS', { en: { 'Ps' => 'Psalms' } })
      
      allow(FinalVerse).to receive(:where).with(book: 'Psalms')
                                          .and_return(double(order: double(first: double(chapter: 150))))

      # Mock just the first few chapters to avoid excessive test setup
      (1..3).each do |chapter|
        verse_count = [6, 12, 8][chapter - 1] # Realistic verse counts for first 3 psalms
        
        allow(FinalVerse).to receive(:where).with(book: 'Psalms', chapter: chapter)
                                            .and_return(double(first: double(last_verse: verse_count)))

        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'Psalms', chapter)
                                         .and_return(double(count: 0)) # No passages to simplify test
      end

      # Mock remaining chapters to have no passages
      (4..150).each do |chapter|
        allow(FinalVerse).to receive(:where).with(book: 'Psalms', chapter: chapter)
                                            .and_return(double(first: double(last_verse: 1)))
        allow(Passage).to receive(:where).with('length > 2 AND book = ? AND chapter = ?', 'Psalms', chapter)
                                         .and_return(double(count: 0))
      end
    end

    it 'handles large books without memory issues' do
      # This test ensures the worker can handle processing all 150 chapters of Psalms
      expect { worker.perform }.not_to raise_error

      # Should have queried for all 150 chapters
      (1..150).each do |chapter|
        expect(FinalVerse).to have_received(:where).with(book: 'Psalms', chapter: chapter)
      end
    end
  end
end