require 'spec_helper'

describe Api::V1::CredentialsController do
  
  let(:user)        { FactoryBot.create(:user) }

  describe 'GET #me' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true, :resource_owner_id => user.id }

      it 'responds with 200' do
        get :me, params: {version: 1}, format: :json
        expect(response.status).to eq(200)
      end

      it 'returns the user as json' do
        get :me, params: {version: 1}, format: :json

        # Would be nice to use this instead but user.to_json has an override in model
        # response.body.should == user.to_json

        api_response = JSON.parse( response.body )
        user_json    = { "response" => user.serializable_hash }

        # Remove date fields. Formats are different and we don't really care
        api_response["response"].delete("created_at")
        api_response["response"].delete("updated_at")
        api_response["response"].delete("last_activity_date")

        user_json["response"].delete("created_at")
        user_json["response"].delete("updated_at")
        user_json["response"].delete("last_activity_date")

        api_response.should == user_json
      end

    end

    context 'no valid access token' do
      it 'responds with 401 when unauthorized' do
        get :me, params: {}, format: :json
        response.status.should eq(401)
      end

    end

  end

end