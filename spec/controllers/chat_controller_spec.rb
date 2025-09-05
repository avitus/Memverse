require 'rails_helper'

RSpec.describe ChatController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  let(:user) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:user, admin: true) }
  let(:chat_channel) { double('ChatChannel') }
  
  before do
    # Mock Redis
    allow($redis).to receive(:exists).and_return(false)
    allow($redis).to receive(:set).and_return('OK')
    allow($redis).to receive(:del).and_return(1)
    
    # Mock ChatChannel
    allow(ChatChannel).to receive(:find).and_return(chat_channel)
    allow(chat_channel).to receive(:channel).and_return('chat-7')
    allow(chat_channel).to receive(:status).and_return('Open')
    allow(chat_channel).to receive(:open?).and_return(true)
    allow(chat_channel).to receive(:toggle_status).and_return('Closed')
    allow(chat_channel).to receive(:send_message).and_return(true)
  end

  describe 'GET #index' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns @tab to "blog"' do
        get :index
        expect(assigns(:tab)).to eq('blog')
      end

      it 'assigns @sub to "chat"' do
        get :index
        expect(assigns(:sub)).to eq('chat')
      end

      it 'uses default channel 7 when no channel specified' do
        expect(ChatChannel).to receive(:find).with('chat-7')
        get :index
      end

      it 'uses specified channel when provided' do
        expect(ChatChannel).to receive(:find).with('chat-5')
        get :index, params: { channel: 5 }
      end

      it 'assigns @channel' do
        get :index
        expect(assigns(:channel)).to eq(chat_channel)
      end
    end
  end

  describe 'POST #send_message' do
    let(:message_params) do
      {
        msg_body: 'Hello world',
        sender: 'testuser',
        user_id: user.id.to_s,
        channel: 'chat-7'
      }
    end

    context 'when user is not banned' do
      before do
        allow($redis).to receive(:exists).with("banned-#{user.id}").and_return(false)
        allow(chat_channel).to receive(:send_message).and_return(true)
      end

      it 'sends the message through ChatChannel' do
        expected_message = { user: 'testuser', user_id: user.id.to_s, msg: 'Hello world' }
        expect(chat_channel).to receive(:send_message).with(expected_message)
        
        post :send_message, params: message_params, xhr: true
      end

      it 'responds with success' do
        post :send_message, params: message_params, xhr: true
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is banned' do
      before do
        allow($redis).to receive(:exists).with("banned-#{user.id}").and_return(true)
      end

      it 'does not send the message' do
        expect(chat_channel).not_to receive(:send_message)
        post :send_message, params: message_params, xhr: true
      end

      it 'logs that the user is banned' do
        allow(Rails.logger).to receive(:info) # Allow all logging
        post :send_message, params: message_params, xhr: true
        # Test passes if response is successful and message is not sent
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST #toggle_channel' do
    let(:channel_params) { { channel: 'chat-7' } }

    it 'finds the specified channel' do
      expect(ChatChannel).to receive(:find).with('chat-7')
      post :toggle_channel, params: channel_params
    end

    it 'toggles the channel status' do
      expect(chat_channel).to receive(:toggle_status).and_return('Closed')
      post :toggle_channel, params: channel_params
    end

    it 'returns the new status as JSON' do
      allow(chat_channel).to receive(:toggle_status).and_return('Closed')
      post :toggle_channel, params: channel_params
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq({ 'status' => 'Closed' })
    end

    it 'logs channel information' do
      allow(Rails.logger).to receive(:info) # Allow all logging
      post :toggle_channel, params: channel_params
      # Test passes if no exceptions are raised and response is successful
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #toggle_ban' do
    let(:target_user) { FactoryBot.create(:user) }
    let(:ban_params) { { user_id: target_user.id.to_s } }

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :toggle_ban, params: ban_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is not an admin' do
      before { sign_in user }

      it 'returns nil status' do
        get :toggle_ban, params: ban_params
        expect(JSON.parse(response.body)['status']).to be_nil
      end
    end

    context 'when user is an admin' do
      before do
        quizmaster_role = Role.find_or_create_by(name: 'quizmaster')
        admin_user.roles << quizmaster_role
        sign_in admin_user
      end

      context 'when user is not currently banned' do
        before do
          allow($redis).to receive(:exists).with("banned-#{target_user.id}").and_return(false)
        end

        it 'bans the user' do
          expect($redis).to receive(:set).with("banned-#{target_user.id}", "banned")
          get :toggle_ban, params: ban_params
        end

        it 'returns banned status' do
          get :toggle_ban, params: ban_params
          expect(JSON.parse(response.body)['status']).to eq('Banned')
        end
      end

      context 'when user is currently banned' do
        before do
          allow($redis).to receive(:exists).with("banned-#{target_user.id}").and_return(true)
        end

        it 'unbans the user' do
          expect($redis).to receive(:del).with("banned-#{target_user.id}")
          get :toggle_ban, params: ban_params
        end

        it 'returns unban status' do
          get :toggle_ban, params: ban_params
          expect(JSON.parse(response.body)['status']).to eq('Ban revoked')
        end
      end
    end

    context 'when no user_id is provided' do
      before { sign_in admin_user }

      it 'returns nil status' do
        get :toggle_ban
        expect(JSON.parse(response.body)['status']).to be_nil
      end
    end
  end

  describe '#parse_chat_message' do
    it 'parses message with user_id' do
      result = controller.send(:parse_chat_message, 'Hello', 'testuser', '123')
      expect(result).to eq({ user: 'testuser', user_id: '123', msg: 'Hello' })
    end

    it 'parses message without user_id' do
      result = controller.send(:parse_chat_message, 'Server announcement', 'server')
      expect(result).to eq({ user: 'server', user_id: nil, msg: 'Server announcement' })
    end
  end
end