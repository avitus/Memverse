require 'spec_helper'

describe Api::V1::CredentialsController do
  describe 'GET #me (integrated)' do

    let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") }
    let!(:user)        { User.create!(:email => "ax@b.com", :password => "abc123", :password_confirmation => "abc123") }
    let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }

    it 'responds with 200' do
      get :me, :format => :json, :access_token => token.token
      response.status.should eq(200)
    end

    it 'returns the user as json' do
      get :me, :format => :json, :access_token => token.token

      # Would be nice to use this instead but user.to_json has an override in model
      # response.body.should == user.to_json

      api_response = JSON.parse( response.body )
      user_json    = { "response" => user.serializable_hash }

      # Remove date fields. Formats are different and we don't really care
      api_response["response"].delete("created_at")
      api_response["response"].delete("updated_at")

      user_json["response"].delete("created_at")
      user_json["response"].delete("updated_at")

      api_response.should == user_json
    end
  end

  describe 'GET #me (stubbed)' do
    let(:token) { stub(:token => "some-token", :accessible? => true) }
    let(:user)  { stub(:to_json => "{}") }

    before do
      controller.stub(:doorkeeper_token) { token }
      controller.stub(:current_resource_owner) { user }
    end

    it 'responds with 200' do
      get :me, :format => :json
      response.status.should eq(200)
    end

    it 'responds with 401 when unauthorized' do
      token.stub :accessible? => false
      get :me, :format => :json
      response.status.should eq(401)
    end

  end
end