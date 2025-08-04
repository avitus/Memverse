require 'spec_helper'

describe PopversesController, "Dangerous Send Protection", type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user)
    @user.confirm
    sign_in @user
    
    # Create test popverse with various translation columns
    Popverse.create!(
      pop_ref: "John 3:16",
      book: "John",
      chapter: 3,
      versenum: 16,
      num_users: 100,
      niv: 1,
      niv_text: "For God so loved...",
      esv: 2,
      esv_text: "For God so loved..."
    )
  end
  
  describe "GET 'index'" do
    it "prevents arbitrary method execution via translation parameter" do
      # Attempt to call dangerous methods
      dangerous_params = [
        'destroy',
        'delete',
        'update_all',
        'connection',
        'execute',
        '__send__',
        'instance_eval',
        'class_eval',
        'eval'
      ]
      
      dangerous_params.each do |param|
        expect {
          get :index, params: { tl: param }
        }.not_to raise_error
        
        expect(response).to be_successful
        # Verify the popverse still exists
        expect(Popverse.count).to eq(1)
      end
    end
    
    it "only allows valid translation methods" do
      # Valid translations should work
      valid_translations = ['NIV', 'ESV']
      
      valid_translations.each do |tl|
        get :index, params: { tl: tl }, format: :json
        expect(response).to be_successful
        
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json).not_to be_empty
      end
    end
    
    it "handles invalid translation parameters gracefully" do
      get :index, params: { tl: 'invalid_translation' }, format: :json
      expect(response).to be_successful
      
      # Should return empty array for invalid translation
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end
  end
end