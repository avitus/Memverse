require 'spec_helper'

describe Api::V1::UsersController do

  let(:user)        { FactoryGirl.create(:user) }

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

      it 'fails to update the user when other than logged-in user' do
        @user = FactoryGirl.create(:user)
        put :update, {id: @user.id, user: {translation: "NNV"}}, version: 1, :format => :json
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
