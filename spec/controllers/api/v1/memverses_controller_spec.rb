require 'spec_helper'

describe Api::V1::MemversesController do

  describe 'GET #index' do

    let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") } # OAuth application
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'responds with 200' do
      get :index, :version => 1, :format => :json, :access_token => token.token
      response.status.should eq(200)
    end

    it 'returns user memory verses as json' do
      get :index, :version => 1, :format => :json, :access_token => token.token
      json.should == JSON.parse([mv].to_json)
    end

    it 'responds with 401 when unauthorized' do
      token.stub :accessible? => false
      get :index, :version => 1, :format => :json
      response.status.should eq(401)
    end
  end

  describe 'POST #create (with scopes)' do

    let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") } # OAuth application
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }
    let!(:verse)       { FactoryGirl.create(:verse)}

    it 'creates the memverse' do
      expect {
        post :create, :id => verse.id, :version => 1, :format => :json, :access_token => token.token
      }.to change(Memverse, :count).by(1)
      response.status.should eq(201)
      json["verse_id"].should == verse.id
      json["user_id"].should  == user.id
    end
  end

  describe 'PUT #update' do

    let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") } # OAuth application
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'updates the memverse' do
      put :update, :id => mv.id, :q => 5, :version => 1, :format => :json, :access_token => token.token
      response.status.should eq(200)
      json["test_interval"].should         == 4
      json["efactor"].to_f.should          == 2.1
      json["rep_n"].should                 == 2
      json["attempts"].should              == 1
      Date.parse(json["next_test"]).should == Date.today + 4
    end
  end

  describe 'DELETE #destroy' do

    let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") } # OAuth application
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'deletes the memverse' do
      expect {
        delete :destroy, :id => mv.id, :version => 1, :format => :json, :access_token => token.token
      }.to change(Memverse, :count).by(-1)
      response.status.should eq (200)
    end
  end

end
