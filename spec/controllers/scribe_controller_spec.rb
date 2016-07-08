require 'spec_helper'

describe ScribeController do

  before(:each) do
    login_scribe
  end

  # This should return the minimal set of attributes required to create a valid
  # Verse. As you add validations to Verse, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    { translation: "NIV", book_index: 43, book: "John", chapter: 11, versenum: 35,
      text: "Jesus wept.", verified: false, error_flag: true }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VersesController. Be sure to keep this updated too.
  def valid_session
    {"warden.user.user.key" => session["warden.user.user.key"]}
  end

  describe "verify verse" do

    it "verifies a verse" do
      verse1 = Verse.create! valid_attributes
      expect {
 	  	get :verify_verse, {:id => verse1.to_param}, valid_session
 	  	verse1.reload
      }.to change{verse1.verified}.from(false).to(true)
    end

    it "removes the error flag" do
      verse2 = Verse.create! valid_attributes
      expect {
 	  	get :verify_verse, {:id => verse2.to_param}, valid_session 
 	  	verse2.reload   	
      }.to change{verse2.error_flag}.from(true).to(false)
    end

  end

end

