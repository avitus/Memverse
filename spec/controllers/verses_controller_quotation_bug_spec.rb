require 'rails_helper'

RSpec.describe VersesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  
  before do
    sign_in user
  end
  
  describe 'POST #set_verse_text (quotation mark bug)' do
    context 'when updating verse text to remove quotation marks' do
      let(:verse_text_with_quote) { "'He who overcomes, I will make him a pillar in the temple of My God, and he will not go out from it anymore; and I will write on him the name of My God, and the name of the city of My God, the new Jerusalem, which comes down out of heaven from My God, and My new name." }
      let(:verse_text_without_quote) { "He who overcomes, I will make him a pillar in the temple of My God, and he will not go out from it anymore; and I will write on him the name of My God, and the name of the city of My God, the new Jerusalem, which comes down out of heaven from My God, and My new name." }
      
      it 'should save the verse without the quotation mark' do
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: '3', 
          versenum: '12', 
          translation: 'NAS',
          text: verse_text_with_quote
        )
        
        # Simulate jeditable AJAX request
        post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
        
        # Check that the verse was saved without the quotation mark
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
        expect(verse.text).not_to start_with("'")
        
        # Check the response
        expect(response.body).to eq(verse_text_without_quote)
      end
      
      it 'should handle text that already has no quotation marks' do
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: '3', 
          versenum: '10', 
          translation: 'NAS',
          text: verse_text_without_quote
        )
        
        # Try to save the same text without quotes
        post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
        
        # Should remain without quotes
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
        expect(verse.text).not_to start_with("'")
      end
    end
  end
end