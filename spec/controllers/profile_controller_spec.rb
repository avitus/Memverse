require 'spec_helper'

describe ProfileController do

  before (:each) do
    @user = FactoryBot.create(:user)
    @user.confirm
    sign_in @user
  end

  describe "GET 'unsubscribe'" do

    it "should unsubsribe user from all emails" do
      get :unsubscribe, params: {email: @user.email}
      expect(response).to be_success
      expect(@user.reload.newsletters).to be false
      expect(@user.reminder_freq).to eq("Never")
    end

  end

end