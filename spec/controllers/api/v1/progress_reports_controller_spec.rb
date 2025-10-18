require 'spec_helper'

describe Api::V1::ProgressReportsController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
  let(:user) { FactoryBot.create(:user) }

  describe 'GET #index' do
    before do
      FactoryBot.create_list(:progress_report, 3, user: user)
    end

    it "responds with 200" do
      get :index, params: {version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "returns user progress reports as json" do
      get :index, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]).to be_present
      expect(body["response"].length).to eq(3)
    end

    it "only returns progress reports for current user" do
      other_user = FactoryBot.create(:user)
      FactoryBot.create_list(:progress_report, 2, user: other_user)

      get :index, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"].length).to eq(3) # Only current user's reports
    end

    it "supports pagination" do
      get :index, params: {page: 1, version: 1}, format: :json
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to have_key("pagination")
    end
  end

  context "without valid access token" do
    before do
      allow(controller).to receive(:doorkeeper_token) { nil }
    end

    it "responds with 401 when unauthorized" do
      get :index, params: {version: 1}, format: :json
      expect(response.status).to eq(401)
    end
  end

end
