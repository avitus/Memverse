require 'rails_helper'

RSpec.describe VersesController, type: :controller do
  let(:verse_text_with_quote) { "'He who overcomes, I will make him a pillar in the temple of My God" }
  let(:verse_text_without_quote) { "He who overcomes, I will make him a pillar in the temple of My God" }
  
  let(:verse) do
    FactoryBot.create(:verse, 
      book: 'Revelation',
      book_index: 66,
      chapter: '3', 
      versenum: '12', 
      translation: 'NAS',
      text: verse_text_with_quote
    )
  end
  
  describe 'POST #set_verse_text permissions' do
    context 'when user is an admin' do
      let(:admin_user) { FactoryBot.create(:user) }
      
      before do
        admin_user.roles << FactoryBot.create(:role, name: 'admin')
        sign_in admin_user
      end
      
      it 'allows editing verses' do
        post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
        
        expect(response).to be_successful
        expect(response.body).to eq(verse_text_without_quote)
        
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
      end
    end
    
    context 'when user is a scribe' do
      let(:scribe_user) { FactoryBot.create(:user) }
      
      before do
        scribe_user.roles << FactoryBot.create(:role, name: 'scribe')
        sign_in scribe_user
      end
      
      it 'should allow editing verses (but currently may not due to missing authorization check)' do
        post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
        
        # This SHOULD work since scribes have :manage permission on Verse
        expect(response).to be_successful
        expect(response.body).to eq(verse_text_without_quote)
        
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
      end
    end
    
    context 'when user is a regular user' do
      let(:regular_user) { FactoryBot.create(:user) }
      
      before do
        sign_in regular_user
      end
      
      it 'should NOT allow editing verses (but currently allows due to missing authorization check)' do
        post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
        
        # Currently this succeeds when it should fail!
        # There's no authorization check in the set_verse_text action
        expect(response).to be_successful
        
        # This shows the security issue - any logged in user can edit verses!
        verse.reload
        expect(verse.text).to eq(verse_text_without_quote)
      end
    end
    
    context 'when user is not logged in' do
      it 'redirects to login' do
        post :set_verse_text, params: { id: verse.id, value: verse_text_without_quote }
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
  
  # Compare with check_verses which properly uses current user's translation
  describe 'GET #check_verses' do
    context 'when user is a scribe with NAS translation' do
      let(:scribe_user) { FactoryBot.create(:user, translation: 'NAS') }
      
      before do
        scribe_user.roles << FactoryBot.create(:role, name: 'scribe')
        sign_in scribe_user
        
        # Create verses that should show up
        @nas_verse = FactoryBot.create(:verse, translation: 'NAS', verified: false, checked_by: nil)
        FactoryBot.create(:memverse, verse: @nas_verse)
        FactoryBot.create(:memverse, verse: @nas_verse)
        @nas_verse.update_column(:memverses_count, 2)
        
        # Create verse that should NOT show up (different translation)
        @niv_verse = FactoryBot.create(:verse, translation: 'NIV', verified: false, checked_by: nil)
        FactoryBot.create(:memverse, verse: @niv_verse)
        FactoryBot.create(:memverse, verse: @niv_verse)
        @niv_verse.update_column(:memverses_count, 2)
      end
      
      it 'only shows verses in the user\'s translation' do
        get :check_verses
        
        expect(response).to be_successful
        expect(assigns(:need_verification)).to include(@nas_verse)
        expect(assigns(:need_verification)).not_to include(@niv_verse)
      end
    end
  end
end