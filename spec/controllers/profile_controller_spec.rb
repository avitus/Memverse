require 'spec_helper'

describe ProfileController do

  before (:each) do
    @user = FactoryBot.create(:user)
    @user.update!(confirmed_at: Time.current)
    sign_in @user
  end

  describe "GET 'unsubscribe'" do

    it "should unsubsribe user from all emails" do
      get :unsubscribe, params: {email: @user.email}
      expect(response).to be_successful
      expect(@user.reload.newsletters).to be false
      expect(@user.reminder_freq).to eq("Never")
    end

  end

  describe "autocomplete actions" do
    
    describe "GET 'country_autocomplete'" do
      before do
        # Create test countries
        Country.create!(name: "US", printable_name: "United States", iso: "US")
        Country.create!(name: "GB", printable_name: "United Kingdom", iso: "GB")
        Country.create!(name: "CA", printable_name: "Canada", iso: "CA")
        Country.create!(name: "AU", printable_name: "Australia", iso: "AU")
      end

      it "returns matching countries starting with query" do
        get :country_autocomplete, params: { term: "Uni" }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response).to include("United States")
        expect(json_response).to include("United Kingdom")
        expect(json_response).not_to include("Canada")
        expect(json_response).not_to include("Australia")
      end

      it "is case insensitive" do
        get :country_autocomplete, params: { term: "uni" }
        json_response = JSON.parse(response.body)
        expect(json_response).to include("United States")
        expect(json_response).to include("United Kingdom")
      end

      it "returns empty array when no matches" do
        get :country_autocomplete, params: { term: "xyz" }
        json_response = JSON.parse(response.body)
        expect(json_response).to eq([])
      end
    end

    describe "GET 'state_autocomplete'" do
      before do
        # Create test states with explicit abbreviations to avoid duplicates
        FactoryBot.create(:american_state, name: "Michigan", abbrev: "MI")
        FactoryBot.create(:american_state, name: "Minnesota", abbrev: "MN")
        FactoryBot.create(:american_state, name: "Mississippi", abbrev: "MS")
        FactoryBot.create(:american_state, name: "Texas", abbrev: "TX")
      end

      it "returns matching states starting with query" do
        get :state_autocomplete, params: { term: "Mi" }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response).to include("Michigan")
        expect(json_response).to include("Minnesota")
        expect(json_response).to include("Mississippi")
        expect(json_response).not_to include("Texas")
      end

      it "is case insensitive" do
        get :state_autocomplete, params: { term: "mi" }
        json_response = JSON.parse(response.body)
        expect(json_response).to include("Michigan")
        expect(json_response).to include("Minnesota")
      end

      it "returns empty array when no matches" do
        get :state_autocomplete, params: { term: "xyz" }
        json_response = JSON.parse(response.body)
        expect(json_response).to eq([])
      end
    end

    describe "GET 'church_autocomplete'" do
      before do
        # Create test churches
        Church.create!(name: "First Baptist Church")
        Church.create!(name: "First Presbyterian Church")
        Church.create!(name: "Grace Community Church")
        Church.create!(name: "Trinity Church")
      end

      it "returns matching churches starting with query" do
        get :church_autocomplete, params: { term: "First" }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response).to include("First Baptist Church")
        expect(json_response).to include("First Presbyterian Church")
        expect(json_response).not_to include("Grace Community Church")
        expect(json_response).not_to include("Trinity Church")
      end

      it "is case insensitive" do
        get :church_autocomplete, params: { term: "first" }
        json_response = JSON.parse(response.body)
        expect(json_response).to include("First Baptist Church")
        expect(json_response).to include("First Presbyterian Church")
      end

      it "returns empty array when no matches" do
        get :church_autocomplete, params: { term: "xyz" }
        json_response = JSON.parse(response.body)
        expect(json_response).to eq([])
      end
    end

    describe "GET 'group_autocomplete'" do
      before do
        # Create test groups
        FactoryBot.create(:group, name: "Youth Bible Study")
        FactoryBot.create(:group, name: "Young Adults Fellowship")
        FactoryBot.create(:group, name: "Men's Prayer Group")
        FactoryBot.create(:group, name: "Women's Bible Study")
      end

      it "returns matching groups starting with query" do
        get :group_autocomplete, params: { term: "You" }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response).to include("Youth Bible Study")
        expect(json_response).to include("Young Adults Fellowship")
        expect(json_response).not_to include("Men's Prayer Group")
        expect(json_response).not_to include("Women's Bible Study")
      end

      it "is case insensitive" do
        get :group_autocomplete, params: { term: "you" }
        json_response = JSON.parse(response.body)
        expect(json_response).to include("Youth Bible Study")
        expect(json_response).to include("Young Adults Fellowship")
      end

      it "returns empty array when no matches" do
        get :group_autocomplete, params: { term: "xyz" }
        json_response = JSON.parse(response.body)
        expect(json_response).to eq([])
      end
    end
  end

  describe "referral features" do
    
    describe "GET 'set_referrer'" do
      it "renders the set_referrer template" do
        get :set_referrer
        expect(response).to be_successful
        expect(response).to render_template('set_referrer')
      end

      it "initializes empty user list" do
        get :set_referrer
        expect(assigns(:user_list)).to eq([])
      end
    end

    describe "GET 'set_as_referrer'" do
      let(:referrer) { FactoryBot.create(:user) }
      
      it "sets the referrer for current user" do
        get :set_as_referrer, params: { id: referrer.id }
        expect(@user.reload.referred_by).to eq(referrer.id)
        expect(flash[:notice]).to eq("You have set your referrer as: #{referrer.name_or_login}")
        expect(response).to redirect_to(referrals_path(@user))
      end

      it "prevents self-referral" do
        # Ensure user starts with no referrer
        @user.update(referred_by: nil)
        
        get :set_as_referrer, params: { id: @user.id }
        expect(@user.reload.referred_by).to be_nil
        expect(flash[:notice]).to eq("You cannot refer yourself!")
        expect(response).to redirect_to(referrals_path(@user))
      end

      it "prevents circular referrals" do
        @user.update(referred_by: referrer.id)
        referrer.update(referred_by: @user.id)
        
        get :set_as_referrer, params: { id: referrer.id }
        expect(@user.reload.referred_by).to eq(referrer.id) # Should remain unchanged
        expect(flash[:notice]).to eq("You cannot be referred by a person you referred.")
        expect(response).to redirect_to(referrals_path(@user))
      end
    end

    describe "GET 'referrals'" do
      let(:referrer) { FactoryBot.create(:user) }
      let(:referee1) { FactoryBot.create(:user, referred_by: @user.id) }
      let(:referee2) { FactoryBot.create(:user, referred_by: @user.id) }
      let(:level_two_referee) { FactoryBot.create(:user, referred_by: referee1.id) }
      
      before do
        @user.update(referred_by: referrer.id)
        referee1
        referee2
        level_two_referee
      end

      it "shows referral information for current user" do
        get :referrals, params: { id: @user.id }
        expect(response).to be_successful
        expect(response).to render_template('referrals')
        expect(assigns(:user)).to eq(@user)
        expect(assigns(:referrer)).to eq(referrer)
        expect(assigns(:referees)).to include(referee1, referee2)
        expect(assigns(:level_two)).to include(level_two_referee)
      end

      it "shows referral information for other users" do
        get :referrals, params: { id: referee1.id }
        expect(response).to be_successful
        expect(assigns(:user)).to eq(referee1)
        expect(assigns(:referrer)).to eq(@user)
        expect(assigns(:referees)).to include(level_two_referee)
      end

      it "handles users with no referrer" do
        # Create a user with no referrer
        lonely_user = FactoryBot.create(:user, referred_by: nil)
        lonely_user.update!(confirmed_at: Time.current)
        
        # Sign in as this user
        sign_in lonely_user
        
        # Access their own referrals page
        get :referrals, params: { id: lonely_user.id }
        
        expect(response).to be_successful
        expect(assigns(:user)).to eq(lonely_user)
        expect(assigns(:referrer)).to be_nil
        expect(assigns(:referees)).to be_empty
        expect(assigns(:level_two)).to be_empty
      end

      it "cleans up self-referrals" do
        # Create a user that somehow referred themselves (should be prevented now)
        self_referral_user = FactoryBot.create(:user)
        self_referral_user.update_column(:referred_by, self_referral_user.id) # Bypass validation
        
        get :referrals, params: { id: self_referral_user.id }
        expect(response).to be_successful
        expect(assigns(:referrer)).to be_nil
        expect(self_referral_user.reload.referred_by).to be_nil
        expect(flash[:notice]).to eq("You can't refer yourself!")
      end
    end

    describe "POST 'search_user'" do
      let!(:john_doe) { FactoryBot.create(:user, name: "John Doe", email: "john@example.com", login: "johndoe") }
      let!(:jane_smith) { FactoryBot.create(:user, name: "Jane Smith", email: "jane@example.com", login: "janesmith") }
      
      it "finds users by name" do
        post :search_user, params: { search_param: "John Doe" }, xhr: true
        expect(response).to be_successful
        expect(assigns(:user_list)).to include(john_doe)
        expect(assigns(:user_list)).not_to include(jane_smith)
      end

      it "finds users by email" do
        post :search_user, params: { search_param: "jane@example.com" }, xhr: true
        expect(response).to be_successful
        expect(assigns(:user_list)).to include(jane_smith)
        expect(assigns(:user_list)).not_to include(john_doe)
      end

      it "finds users by login" do
        post :search_user, params: { search_param: "johndoe" }, xhr: true
        expect(response).to be_successful
        expect(assigns(:user_list)).to include(john_doe)
        expect(assigns(:user_list)).not_to include(jane_smith)
      end

      it "returns empty array for no matches" do
        post :search_user, params: { search_param: "nonexistent" }, xhr: true
        expect(response).to be_successful
        expect(assigns(:user_list)).to be_empty
      end

      it "returns empty array for empty search" do
        post :search_user, params: { search_param: "" }, xhr: true
        expect(response).to be_successful
        expect(assigns(:user_list)).to be_empty
      end

      it "limits results to 5 users" do
        6.times { FactoryBot.create(:user, name: "Test User") }
        post :search_user, params: { search_param: "Test User" }, xhr: true
        expect(assigns(:user_list).count).to eq(5)
      end
    end
  end

end