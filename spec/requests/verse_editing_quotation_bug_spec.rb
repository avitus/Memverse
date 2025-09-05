require 'rails_helper'

RSpec.describe 'Verse editing quotation mark bug', type: :request do
  let(:user) { FactoryBot.create(:user, translation: 'NAS') }
  
  before do
    sign_in user
  end
  
  describe 'POST /verses/:id/set_verse_text' do
    context 'with Revelation 3:12 NASB' do
      let(:verse_text_with_quote) { "'He who overcomes, I will make him a pillar in the temple of My God, and he will not go out from it anymore; and I will write on him the name of My God, and the name of the city of My God, the new Jerusalem, which comes down out of heaven from My God, and My new name." }
      let(:verse_text_without_quote) { "He who overcomes, I will make him a pillar in the temple of My God, and he will not go out from it anymore; and I will write on him the name of My God, and the name of the city of My God, the new Jerusalem, which comes down out of heaven from My God, and My new name." }
      
      it 'saves and returns text without quotation mark' do
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: 3, 
          versenum: 12, 
          translation: 'NAS',
          text: verse_text_with_quote
        )
        
        # Simulate jeditable AJAX request
        post set_verse_text_verse_path(verse), params: { 
          id: verse.id, 
          value: verse_text_without_quote
        }
        
        # Check response
        expect(response).to be_successful
        expect(response.body).to eq(verse_text_without_quote)
        
        # Check database
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
        expect(verse.text).not_to start_with("'")
      end
      
      it 'handles jeditable parameters correctly' do
        verse = FactoryBot.create(:verse, 
          book: 'Revelation',
          book_index: 66,
          chapter: 3, 
          versenum: 12, 
          translation: 'NAS',
          text: verse_text_with_quote
        )
        
        # This simulates what jeditable actually sends
        post set_verse_text_verse_path(verse), params: { 
          id: verse.id.to_s,
          value: verse_text_without_quote,
          editable: { id: verse.id.to_s }
        }
        
        expect(response).to be_successful
        
        # The response should be the saved text
        expect(response.body).to eq(verse_text_without_quote)
        
        # Check database
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
      end
    end
  end
end