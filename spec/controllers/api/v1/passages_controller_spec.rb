require 'spec_helper'

describe Api::V1::PassagesController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
  let(:user) { FactoryBot.create(:user) }
  let!(:passage) { FactoryBot.create(:passage, user: user) }

  describe 'GET #index' do
    it "responds with 200" do
      get :index, params: {version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "returns user passages as json" do
      get :index, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]).to be_present
      expect(body["response"].length).to eq(1) # passage from let!
    end

    it "returns passages ordered by book, chapter, and verse" do
      get :index, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      passages = body["response"]
      expect(passages).to be_an(Array)
    end

    it "supports pagination" do
      get :index, params: {page: 1, version: 1}, format: :json
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to have_key("pagination")
    end
  end

  describe 'GET #show' do
    it "responds with 200" do
      get :show, params: {id: passage.id, version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "returns the passage as json" do
      get :show, params: {id: passage.id, version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]["id"]).to eq(passage.id)
    end

    it "only returns passages belonging to current user" do
      other_user = FactoryBot.create(:user)
      other_passage = FactoryBot.create(:passage, user: other_user)

      expect {
        get :show, params: {id: other_passage.id, version: 1}, format: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'DELETE #destroy' do
    it "responds with 204 no content" do
      delete :destroy, params: {id: passage.id, version: 1}, format: :json
      expect(response.status).to eq(204)
    end

    it "deletes the passage" do
      passage_id = passage.id
      expect {
        delete :destroy, params: {id: passage_id, version: 1}, format: :json
      }.to change { user.passages.count }.by(-1)
    end

    it "only deletes passages belonging to current user" do
      other_user = FactoryBot.create(:user)
      other_passage = FactoryBot.create(:passage, user: other_user)

      expect {
        delete :destroy, params: {id: other_passage.id, version: 1}, format: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when passage cannot be found" do
      it "raises RecordNotFound error" do
        expect {
          delete :destroy, params: {id: 99999, version: 1}, format: :json
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
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
