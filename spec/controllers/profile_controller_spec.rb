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

end