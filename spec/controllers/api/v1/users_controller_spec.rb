require 'spec_helper'

describe Api::V1::UsersController do

  let(:user)        { FactoryGirl.create(:user) }

  describe 'POST #create' do 
    it 'creates a new user' do 
      expect {
        post :create, :user => {:name => 'Test User', :email => 'test@memverse.com', :password => 'password123' }, :version => 1, :format => :json
      }.to change(User, :count).by(1)
      response.status.should eq(200)
    end

    it 'should not allow duplicate emails' do 
      expect {
        post :create, :user => {:name => 'Test User', :email => 'test@memverse.com', :password => 'password123' }, :version => 1, :format => :json
        post :create, :user => {:name => 'Test User', :email => 'test@memverse.com', :password => 'password123' }, :version => 1, :format => :json
      }.to change(User, :count).by(1)
      response.status.should eq(401)
    end

  end

  describe 'GET #show' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      it 'responds with 200' do
        get :show, id: user.id, version: 1, :format => :json
        response.status.should eq(200)
      end

      #it 'returns user attributes as json' do
      #  get :show, id: user.id, version: 1, :format => :json, access_token: token.token
      #  json.should == JSON.parse(user.to_json)
      #end

    end

    context 'no valid access token' do
      it 'responds with 401 when unauthorized' do
        get :show, id: user.id, version: 1, :format => :json
        response.status.should eq(401)
      end
    end

  end

  describe 'PUT #update' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      # ALV: I'm not sure whether this test is valid. RocketPants is returning an 'InvalidVersion' exception
      # it 'records device tokens for mobile devices' do 
      #   @mobile_user = FactoryGirl.create(:user)
      #   put :update, {id: @mobile_user.id, user: {device_token: "EA27D02BF0AABF0DB601D0AB5DF9BC70AC43A9C6B1E155882D48BCB328D901CB", device_type: "iOS"}}, :format => :json, version: 1
      #   response.status.should eq(200)
      # end

      # ALV: I'm not sure whether this test is valid. RocketPants is returning an 'InvalidVersion' exception
      it 'fails to update the user when other than logged-in user' do
        @user = FactoryGirl.create(:user)  # This user is not the one from the 'authenticated with valid token' context
        put :update, {id: @user.id, user: {translation: "NNV"}}, :format => :json, version: 1
        response.status.should eq(404)
      end

    end

    #it 'updates the user' do
      #get :show, id: user.id, version: 1, :format => :json, access_token: token.token

      # Translation initially NIV
    #  user.translation.should == "NIV"

      # Change to NNV
    #  put :update, {id: user.id, user: {translation: "NNV"}}, version: 1, :format => :json, access_token: token.token
    #  response.status.should eq(200)
    #  json["translation"].should == "NNV"
    #end
  end

end
