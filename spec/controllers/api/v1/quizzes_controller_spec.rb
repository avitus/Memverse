require 'spec_helper'

describe Api::V1::QuizzesController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
  let(:user) { FactoryBot.create(:user) }
  let!(:quiz) { FactoryBot.create(:quiz) }

  describe 'GET #index' do
    before do
      FactoryBot.create_list(:quiz, 2)
    end

    it "responds with 200" do
      get :index, params: {version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "returns all quizzes as json" do
      get :index, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]).to be_present
      expect(body["response"].length).to eq(3) # quiz + 2 more
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
      get :show, params: {id: quiz.id, version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "returns the quiz as json" do
      get :show, params: {id: quiz.id, version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]["id"]).to eq(quiz.id)
    end
  end

  describe 'GET #upcoming' do
    it "responds with 200" do
      get :upcoming, params: {id: quiz.id, version: 1}, format: :json
      expect(response.status).to eq(200)
    end

    it "defaults to quiz id 1 when no id provided" do
      default_quiz = FactoryBot.create(:quiz, id: 1)
      get :upcoming, params: {version: 1}, format: :json
      body = JSON.parse(response.body)
      expect(body["response"]["id"]).to eq(1)
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
