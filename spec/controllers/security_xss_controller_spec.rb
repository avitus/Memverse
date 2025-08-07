require 'spec_helper'

describe "XSS Protection" do
  
  describe MemversesController, type: :controller do
    before(:each) do
      @user = FactoryBot.create(:user)
      @user.confirm
      sign_in @user
    end
    
    describe "GET 'home'" do
      it "properly stores devotion content that will be sanitized in the view" do
        # Make sure user doesn't need quick start
        @user.update(translation: 'NIV')
        FactoryBot.create(:memverse, user: @user)
        
        # Create a devotion with potentially malicious content
        malicious_content = '<script>alert("XSS")</script><p>Safe content</p><img src=x onerror=alert("XSS")>'
        devotion = Devotion.create!(
          name: "Spurgeon Morning",
          month: Date.today.month,
          day: Date.today.day,
          thought: malicious_content,
          ref: "John 3:16"
        )
        
        get :home
        
        # Verify the action completes successfully
        expect(response.status).to eq(200)
        
        # Verify the devotion is assigned correctly
        expect(assigns(:dd)).to eq(devotion)
        
        # The actual XSS protection happens in the view via sanitize()
        # This test confirms the controller passes the data correctly
      end
    end
  end

  describe ReadingController, type: :controller do
    before(:each) do
      @user = FactoryBot.create(:user)
      @user.confirm
      sign_in @user
    end
    
    describe "GET 'chapter'" do
      it "escapes verse text properly" do
        # Create a verse with HTML content
        verse = Verse.create!(
          translation: "NIV",
          book: "Psalms",
          book_index: 19,
          chapter: 117,
          versenum: 2,
          text: '<script>alert("XSS")</script>For great is his love toward us...'
        )
        
        get :chapter, params: { bk: "Psalms", ch: 117 }, format: :html
        
        expect(response).to be_successful
        # Check that the script tag is not executed
        expect(response.body).not_to include('<script>alert')
        # The content should be escaped or stripped
        expect(response.body).to include('For great is his love toward us')
      end
    end
  end

  describe ScribeController, type: :controller do
    before(:each) do
      @user = FactoryBot.create(:user)
      @user.confirm
      sign_in @user
      # Mock the authorization for scribe actions
      allow(controller).to receive(:in_scrivenership).and_return(true)
    end
    
    describe "POST 'edit_verse'" do
      it "escapes verse text in edit_verse response" do
        verse = FactoryBot.create(:verse, text: "Original text")
        
        malicious_text = '<img src=x onerror=alert("XSS")>New text'
        
        post :edit_verse, params: { 
          pk: verse.id, 
          value: malicious_text 
        }, xhr: true
        
        expect(response.body).not_to include('<img src=x')
        expect(response.body).not_to include('onerror=')
      end
    end
  end
end