require 'spec_helper'

describe Api::V1::FinalVersesController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
  let(:user) { FactoryBot.create(:user) }

  describe 'GET #index' do
    it "responds with 200" do
      get :index, params: {version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "returns final verses as json" do
      get :index, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]).to be_present
      # FinalVerse data is pre-loaded with 1189 records
      expect(body["response"].length).to be > 0
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
