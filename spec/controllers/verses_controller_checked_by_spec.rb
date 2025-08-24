require 'rails_helper'

RSpec.describe VersesController, type: :controller do
  let(:scribe_user) { FactoryBot.create(:user, translation: 'NAS') }
  
  before do
    scribe_user.roles << FactoryBot.create(:role, name: 'scribe')
    sign_in scribe_user
  end
  
  describe 'checked_by field behavior' do
    let(:verse_text_with_quote) { "'He who overcomes, I will make him a pillar in the temple of My God" }
    let(:verse_text_without_quote) { "He who overcomes, I will make him a pillar in the temple of My God" }
    
    let!(:verse) do
      v = FactoryBot.create(:verse, 
        book: 'Revelation',
        book_index: 66,
        chapter: '3', 
        versenum: '12', 
        translation: 'NAS',
        text: verse_text_with_quote,
        verified: false,
        checked_by: nil
      )
      # Create memverses to meet the requirement
      FactoryBot.create(:memverse, verse: v)
      FactoryBot.create(:memverse, verse: v)
      v.update_column(:memverses_count, 2)
      v
    end
    
    it 'verse appears in check_verses when checked_by is nil' do
      get :check_verses
      
      expect(assigns(:need_verification)).to include(verse)
    end
    
    it 'verse disappears from check_verses after editing' do
      # First confirm it's there
      get :check_verses
      expect(assigns(:need_verification)).to include(verse)
      
      # Edit the verse
      post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
      
      # Check that the edit was successful
      verse.reload
      expect(verse.text).to eq(verse_text_without_quote)
      expect(verse.checked_by).to eq(scribe_user.login)
      
      # Now check that it's gone from the list
      get :check_verses
      expect(assigns(:need_verification)).not_to include(verse)
    end
    
    it 'multiple verses with same reference but different checked_by status' do
      # Create another verse with same translation but different reference
      verse2 = FactoryBot.create(:verse, 
        book: 'Revelation',
        book_index: 66,
        chapter: '3', 
        versenum: '13', 
        translation: 'NAS',
        text: verse_text_with_quote,
        verified: false,
        checked_by: nil
      )
      FactoryBot.create(:memverse, verse: verse2)
      FactoryBot.create(:memverse, verse: verse2)
      verse2.update_column(:memverses_count, 2)
      
      # Edit the first verse
      post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
      
      # The edited verse should have checked_by set
      verse.reload
      expect(verse.checked_by).to eq(scribe_user.login)
      
      # But verse2 should still appear in check_verses
      get :check_verses
      expect(assigns(:need_verification)).not_to include(verse)
      expect(assigns(:need_verification)).to include(verse2)
    end
  end
end