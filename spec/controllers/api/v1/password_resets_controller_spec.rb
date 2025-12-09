require 'spec_helper'

describe Api::V1::PasswordResetsController do

  let(:user) { FactoryBot.create(:user, email: 'test@example.com') }

  describe 'POST #create' do

    context 'when user exists' do
      it 'sends password reset instructions' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions)

        post :create, params: { email: user.email, version: 1 }, format: :json

        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['response']['message']).to eq("Password reset instructions have been sent to #{user.email}.")
      end
    end

    context 'when user does not exist' do
      it 'still returns success for security reasons' do
        non_existent_email = 'nonexistent@example.com'

        post :create, params: { email: non_existent_email, version: 1 }, format: :json

        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['response']['message']).to eq("Password reset instructions have been sent to #{non_existent_email}.")
      end
    end

    it 'does not require authentication' do
      # No doorkeeper token setup needed
      post :create, params: { email: user.email, version: 1 }, format: :json

      expect(response.status).to eq(200)
    end
  end

  describe 'PUT #update' do

    let(:reset_token) { 'valid_reset_token' }
    let(:new_password) { 'newpassword123' }

    before do
      # Set up the user with a password reset token
      user.send_reset_password_instructions
      @raw_token = user.send(:set_reset_password_token)
    end

    context 'with valid reset token' do
      it 'resets the password successfully' do
        put :update, params: {
          reset_password_token: @raw_token,
          password: new_password,
          password_confirmation: new_password,
          version: 1
        }, format: :json

        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['response']['message']).to eq('Password has been reset successfully.')
        expect(json['response']['user']['email']).to eq(user.email)
        expect(json['response']['user']['id']).to eq(user.id)

        # Verify the password was actually changed
        user.reload
        expect(user.valid_password?(new_password)).to be true
      end
    end

    context 'with invalid reset token' do
      it 'returns an error' do
        put :update, params: {
          reset_password_token: 'invalid_token',
          password: new_password,
          password_confirmation: new_password,
          version: 1
        }, format: :json

        expect(response.status).to eq(422)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('unprocessable_entity')
        expect(json['message']).to eq('Password reset failed')
        expect(json['errors']).to include('Reset password token is invalid')
      end
    end

    context 'with mismatched passwords' do
      it 'returns an error' do
        put :update, params: {
          reset_password_token: @raw_token,
          password: new_password,
          password_confirmation: 'different_password',
          version: 1
        }, format: :json

        expect(response.status).to eq(422)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('unprocessable_entity')
        expect(json['message']).to eq('Password reset failed')
        expect(json['errors']).to include("Password confirmation doesn't match Password")
      end
    end

    context 'with blank password' do
      it 'returns an error' do
        put :update, params: {
          reset_password_token: @raw_token,
          password: '',
          password_confirmation: '',
          version: 1
        }, format: :json

        expect(response.status).to eq(422)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('unprocessable_entity')
        expect(json['message']).to eq('Password reset failed')
        expect(json['errors']).to include("Password can't be blank")
      end
    end

    it 'does not require authentication' do
      # No doorkeeper token setup needed
      put :update, params: {
        reset_password_token: @raw_token,
        password: new_password,
        password_confirmation: new_password,
        version: 1
      }, format: :json

      expect(response.status).to eq(200)
    end
  end

  describe 'Swagger documentation' do
    it 'includes password reset endpoints in Swagger docs' do
      expect(ApidocsController::SWAGGERED_CLASSES).to include(Api::V1::PasswordResetsController)
    end
  end
end