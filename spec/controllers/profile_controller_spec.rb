describe ProfileController do

  before (:each) do
    @user = FactoryBot.create(:user)
    @user.confirm
    sign_in @user
  end

  describe "GET 'unsubscribe'" do

    it "should unsubsribe user from all emails" do
      get :unsubscribe, params: {email: @user.email}
      response.should be_success
      @user.reload.newsletters.should be false
      @user.reminder_freq.should == "Never"
    end

  end

end