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
      api_response = JSON.parse( response.body )["response"]
      api_response.should == JSON.parse([mv].to_json)
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
      Memverse.should_receive(:create!) { stub_model( Memverse ) }
      post :create, :id => verse.id, :version => 1, :format => :json, :access_token => token.token
      puts JSON.parse(response.body)
      response.status.should eq(201)
    end
  end

end
