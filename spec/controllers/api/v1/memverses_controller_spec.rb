require 'spec_helper'

describe Api::V1::MemversesController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }

  describe 'GET #index' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'responds with 200' do
      get :index, params: {version: 1}, format: :json
      response.status.should eq(200)
    end

    it 'returns user memory verses as json' do
      get :index, params: {version: 1}, format: :json
      response.should have_exposed [mv]
    end

  end

  describe 'POST #create (with scopes)' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}

    it 'creates the memverse' do
      expect {
        post :create, params: {id: verse.id, version: 1}, format: :json
      }.to change(Memverse, :count).by(1)
      response.status.should eq(201)
      json["verse"]["id"].should == verse.id
    end
  end

  describe 'PUT #update' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'updates the memverse' do
      put :update, params: {id: mv.id, q: 5, version: 1}, format: :json
      response.status.should eq(200)
      json["test_interval"].should         == 4
      json["efactor"].to_f.should          == 2.1
      json["rep_n"].should                 == 2
      json["ref_interval"].should          == 6      # Don't make changes to the reference interval 
      Date.parse(json["next_test"]).should == Date.today + 4
    end

    it 'increases the reference interval correctly' do
      put :update, params: {id: mv.id, ref_recalled: "true", version: 1}, format: :json
      response.status.should eq(200)
      json["ref_interval"].should              == 9
      json["test_interval"].should             == 1   # Don't make changes to the test_interval
      Date.parse(json["next_ref_test"]).should == Date.today + 9
    end

    it 'decreases the reference interval correctly' do
      put :update, params: {id: mv.id, ref_recalled: "false", version: 1}, format: :json
      response.status.should eq(200)
      json["ref_interval"].should              == 4
      json["test_interval"].should             == 1   # Don't make changes to the test_interval
      Date.parse(json["next_ref_test"]).should == Date.today + 4
    end
  end

  describe 'DELETE #destroy' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'deletes the memverse' do
      expect {
        delete :destroy, params: {id: mv.id, version: 1}, format: :json
      }.to change(Memverse, :count).by(-1)
      response.status.should eq (204)  # server executed the request but body of response contains no data
    end
  end

end
