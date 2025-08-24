require 'rails_helper'

RSpec.describe Verse, type: :model do
  describe 'quotation mark handling bug' do
    context 'when editing verses with quotation marks' do
      let(:verse_text_without_quote) { "He who overcomes, I will make him a pillar in the temple of My God, and he will not go out from it anymore; and I will write on him the name of My God, and the name of the city of My God, the new Jerusalem, which comes down out of heaven from My God, and My new name." }
      let(:verse_text_with_quote) { "'He who overcomes, I will make him a pillar in the temple of My God, and he will not go out from it anymore; and I will write on him the name of My God, and the name of the city of My God, the new Jerusalem, which comes down out of heaven from My God, and My new name." }
      
      it 'should allow removal of quotation marks for Revelation 3:12 NASB1995' do
        # Create a verse with the problematic quotation mark
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: '3', 
          versenum: '12', 
          translation: 'NAS',
          text: verse_text_with_quote
        )
        
        # User tries to update the verse to remove the opening quote
        verse.text = verse_text_without_quote
        verse.save!
        
        # The verse should be saved without the quotation mark
        expect(verse.reload.text).to eq(verse_text_without_quote)
        expect(verse.text).not_to start_with("'")
      end

      it 'should allow removal of quotation marks for Revelation 3:10' do
        verse_with_quote = "'Because you have kept the word of My perseverance, I also will keep you from the hour of testing, that hour which is about to come upon the whole world, to test those who dwell on the earth."
        verse_without_quote = "Because you have kept the word of My perseverance, I also will keep you from the hour of testing, that hour which is about to come upon the whole world, to test those who dwell on the earth."
        
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: '3', 
          versenum: '10', 
          translation: 'NAS',
          text: verse_with_quote
        )
        
        verse.text = verse_without_quote
        verse.save!
        
        expect(verse.reload.text).to eq(verse_without_quote)
      end

      it 'should allow removal of quotation marks for Revelation 3:11' do
        verse_with_quote = "'I am coming quickly; hold fast what you have, so that no one will take your crown."
        verse_without_quote = "I am coming quickly; hold fast what you have, so that no one will take your crown."
        
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: '3', 
          versenum: '11', 
          translation: 'NAS',
          text: verse_with_quote
        )
        
        verse.text = verse_without_quote
        verse.save!
        
        expect(verse.reload.text).to eq(verse_without_quote)
      end
    end

    context 'cleanup_text method' do
      it 'should not add quotation marks when they are removed' do
        verse = FactoryBot.build(:verse, text: "Test text without quotes")
        verse.send(:cleanup_text)
        
        expect(verse.text).to eq("Test text without quotes")
        expect(verse.text).not_to include("'")
        expect(verse.text).not_to include('"')
      end

      it 'should preserve the absence of quotation marks' do
        verse = FactoryBot.build(:verse, text: "He who overcomes will be saved")
        verse.send(:cleanup_text)
        
        expect(verse.text).to eq("He who overcomes will be saved")
      end
    end
  end
end