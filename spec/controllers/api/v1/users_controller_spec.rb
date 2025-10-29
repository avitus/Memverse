require 'spec_helper'

describe Api::V1::UsersController do

  let(:user) { FactoryBot.create(:user) }

  describe 'POST #create' do 

    it 'creates a new user' do 
      expect {
        post :create, params: {user: {name: 'Test User', email: 'test@memverse.com', password: 'password123' }, version: 1}, format: :json
      }.to change(User, :count).by(1)
      expect(response.status).to eq(200)
    end

    it 'should not allow duplicate emails' do 
      expect {
        post :create, params: {user: {name: 'Duplicate User 1', email: 'duplicate@memverse.com', password: 'password123' }, version: 1}, format: :json
        post :create, params: {user: {name: 'Duplicate User 2', email: 'duplicate@memverse.com', password: 'password123' }, version: 1}, format: :json
      }.to change(User, :count).by(1)
      expect(response.status).to eq(403)  # 403 = this operation is forbidden by server
    end

  end

  describe 'GET #show' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      it 'responds with 200' do
        get :show, params: {id: user.id, version: 1}, format: :json
        expect(response.status).to eq(200)
      end

    end

    context 'no valid access token' do
      it 'responds with 401 when unauthorized' do
        get :show, params: {id: user.id, version: 1}, format: :json
        expect(response.status).to eq(401)
      end
    end

  end

  describe 'DELETE #destroy' do

    let(:user_to_delete) { FactoryBot.create(:user, name: 'User to Delete', email: 'delete@memverse.com') }
    let(:other_user) { FactoryBot.create(:user, name: 'Other User', email: 'other@memverse.com') }

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        allow(controller).to receive(:current_resource_owner) { current_user }
      end

      let(:token) { double :acceptable? => true, :resource_owner_id => current_user.id }

      context 'when deleting own account' do
        let(:current_user) { user_to_delete }

        it 'responds with 200' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          expect(response.status).to eq(200)
        end

        it 'deletes the user from the database' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          expect { User.find(user_to_delete.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'returns the deleted user data' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['response']['id']).to eq(user_to_delete.id)
          expect(parsed_response['response']['email']).to eq(user_to_delete.email)
        end

        it 'reduces user count by 1' do
          user_to_delete # ensure user exists before the test
          expect {
            delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          }.to change(User, :count).by(-1)
        end
      end

      context 'when trying to delete another user\'s account' do
        let(:current_user) { other_user }

        it 'responds with 400 (bad request)' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          expect(response.status).to eq(400)
        end

        it 'does not delete the user from the database' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          expect(User.find(user_to_delete.id)).to eq(user_to_delete)
        end

        it 'returns an error message about authorization' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['error']).to eq('bad_request')
          expect(parsed_response['reason']).to include('User is not the signed-in user')
        end

        it 'does not change user count' do
          user_to_delete # ensure user exists
          other_user     # ensure other user exists
          expect {
            delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          }.not_to change(User, :count)
        end
      end

      context 'when trying to delete non-existent user' do
        let(:current_user) { other_user }
        let(:nonexistent_id) { user_to_delete.id + 9999 }

        it 'responds with 400 (bad request)' do
          delete :destroy, params: {id: nonexistent_id, version: 1}, format: :json
          expect(response.status).to eq(400)
        end

        it 'returns an error message about user not found' do
          delete :destroy, params: {id: nonexistent_id, version: 1}, format: :json
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['error']).to eq('bad_request')
          expect(parsed_response['reason']).to include('User could not be found')
        end
      end
    end

    context 'no valid access token' do
      
      it 'responds with 401 when unauthorized' do
        delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
        expect(response.status).to eq(401)
      end

      it 'does not delete the user' do
        delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
        expect(User.find(user_to_delete.id)).to eq(user_to_delete)
      end

      it 'does not change user count' do
        user_to_delete # ensure user exists
        expect {
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
        }.not_to change(User, :count)
      end
    end

    context 'edge cases' do
      
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        allow(controller).to receive(:current_resource_owner) { current_user }
      end

      let(:token) { double :acceptable? => true, :resource_owner_id => current_user.id }
      let(:current_user) { user_to_delete }

      context 'when user has associated data (memverses, etc.)' do
        before do
          # Create some associated data
          verse = FactoryBot.create(:verse)
          FactoryBot.create(:memverse, user: user_to_delete, verse: verse)
        end

        it 'still deletes the user successfully' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          expect(response.status).to eq(200)
          expect { User.find(user_to_delete.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when deletion fails due to database constraints' do
        before do
          # Mock the destroy method to return false
          user_instance = instance_double(User)
          allow(User).to receive(:find_by).with(id: user_to_delete.id.to_s).and_return(user_instance)
          allow(user_instance).to receive(:destroy).and_return(false)
          allow(user_instance).to receive(:id).and_return(user_to_delete.id)
          allow(user_instance).to receive(:!=).and_return(false)  # Mock comparison with current_resource_owner
          allow(user_instance).to receive(:attributes).and_return(user_to_delete.attributes)
        end

        it 'responds with 400 (bad request)' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          expect(response.status).to eq(400)
        end

        it 'returns an error message about deletion failure' do
          delete :destroy, params: {id: user_to_delete.id, version: 1}, format: :json
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['error']).to eq('bad_request')
          expect(parsed_response['reason']).to include('User could not be deleted')
        end
      end
    end

  end

end
