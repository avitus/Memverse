require 'spec_helper'

describe Api::V1::UsersController do

  let(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") } # OAuth application
  let(:user)        { FactoryGirl.create(:user) }
  let(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }

  describe 'GET #show' do

    it 'responds with 200' do
      get :show, id: user.id, version: 1, :format => :json, access_token: token.token
      response.status.should eq(200)
    end

    it 'returns user attributes as json' do
      get :show, id: user.id, version: 1, :format => :json, access_token: token.token
      json.should == JSON.parse(user.to_json)
    end

    it 'responds with 401 when unauthorized' do
      token.update_attribute(:revoked_at, Time.now)

      get :show, id: user.id, version: 1, :format => :json, access_token: token.token
      response.status.should eq(401)
    end
  end

  describe 'PUT #update' do

    it 'fails to update the user when other than logged-in user' do
      @user = FactoryGirl.create(:user)
      put :update, {id: @user.id, user: {translation: "NNV"}}, version: 1, :format => :json, access_token: token.token
      response.status.should eq(401)
    end

    it 'updates the user' do
      #get :show, id: user.id, version: 1, :format => :json, access_token: token.token

      # Translation initially NIV
      user.translation.should == "NIV"

      # Change to NNV
      put :update, {id: user.id, user: {translation: "NNV"}}, version: 1, :format => :json, access_token: token.token
      response.status.should eq(200)
      json["translation"].should == "NNV"
    end
  end

end
