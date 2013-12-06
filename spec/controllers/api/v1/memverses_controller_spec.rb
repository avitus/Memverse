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
      response.body["response"]["count"].should == 1
    end

    it 'responds with 401 when unauthorized' do
      token.stub :accessible? => false
      get :index, :version => 1, :format => :json
      response.status.should eq(401)
    end
  end

  # Need below tests once updates/creates are implemented

  # describe 'POST #create (with scopes)' do
  #   let(:token) do
  #     stub :accessible? => true, :scopes => [:write]
  #   end

  #   before do
  #     controller.stub(:doorkeeper_token) { token }
  #   end

  #   it 'creates the profile' do
  #     Profile.should_receive(:create!) { stub_model(Profile) }
  #     post :create, :format => :json
  #     response.status.should eq(201)
  #   end
  # end

end
