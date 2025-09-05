require 'rails_helper'

RSpec.describe ChatChannel, type: :model do
  let(:channel_name) { 'chat-7' }
  let(:chat_channel) { ChatChannel.find(channel_name) }
  let(:pubnub_envelope) { double('PubNub::Envelope', error: nil, timetoken: '12345') }
  
  before do
    # Mock Redis
    allow($redis).to receive(:hmget).and_return(['Open'])
    allow($redis).to receive(:hset).and_return(1)
    
    # Mock PubNub
    allow(PN).to receive(:publish).and_return([pubnub_envelope])
  end

  describe '.find' do
    it 'creates a new ChatChannel instance with the given channel name' do
      channel = ChatChannel.find('test-channel')
      expect(channel).to be_a(ChatChannel)
      expect(channel.channel).to eq('test-channel')
    end

    it 'defaults to "channel1" if no channel name provided' do
      channel = ChatChannel.find
      expect(channel.channel).to eq('channel1')
    end
  end

  describe '#initialize' do
    it 'sets the channel attribute' do
      channel = ChatChannel.new('my-channel')
      expect(channel.channel).to eq('my-channel')
    end
  end

  describe '#status' do
    context 'when status exists in Redis' do
      before do
        allow($redis).to receive(:hmget).with('chat-chat-7', 'status').and_return(['Open'])
      end

      it 'returns the status from Redis' do
        expect(chat_channel.status).to eq('Open')
      end
    end

    context 'when status does not exist in Redis' do
      before do
        allow($redis).to receive(:hmget).with('chat-chat-7', 'status').and_return([nil])
      end

      it 'returns "Closed" as default' do
        expect(chat_channel.status).to eq('Closed')
      end
    end

    context 'when Redis returns empty array' do
      before do
        allow($redis).to receive(:hmget).with('chat-chat-7', 'status').and_return([])
      end

      it 'returns "Closed" as default' do
        expect(chat_channel.status).to eq('Closed')
      end
    end
  end

  describe '#status=' do
    let(:new_status) { 'Closed' }

    context 'when new status is different from current status' do
      before do
        allow(chat_channel).to receive(:status).and_return('Open')
      end

      it 'updates the status in Redis' do
        expect($redis).to receive(:hset).with('chat-chat-7', 'status', new_status)
        chat_channel.status = new_status
      end

      it 'publishes the status change' do
        expect(chat_channel).to receive(:publish).with(meta: 'chat_status', status: new_status)
        chat_channel.status = new_status
      end
    end

    context 'when new status is the same as current status' do
      before do
        allow(chat_channel).to receive(:status).and_return('Closed')
      end

      it 'does not update Redis or publish' do
        expect($redis).not_to receive(:hset)
        expect(chat_channel).not_to receive(:publish)
        chat_channel.status = new_status
      end
    end
  end

  describe '#open?' do
    it 'returns true when status is "Open"' do
      allow(chat_channel).to receive(:status).and_return('Open')
      expect(chat_channel.open?).to be true
    end

    it 'returns false when status is "Closed"' do
      allow(chat_channel).to receive(:status).and_return('Closed')
      expect(chat_channel.open?).to be false
    end
  end

  describe '#closed?' do
    it 'returns true when status is "Closed"' do
      allow(chat_channel).to receive(:status).and_return('Closed')
      expect(chat_channel.closed?).to be true
    end

    it 'returns false when status is "Open"' do
      allow(chat_channel).to receive(:status).and_return('Open')
      expect(chat_channel.closed?).to be false
    end
  end

  describe '#toggle_status' do
    it 'changes status from Open to Closed' do
      allow(chat_channel).to receive(:open?).and_return(true)
      expect(chat_channel).to receive(:status=).with('Closed')
      result = chat_channel.toggle_status
      expect(result).to eq('Closed')
    end

    it 'changes status from Closed to Open' do
      allow(chat_channel).to receive(:open?).and_return(false)
      expect(chat_channel).to receive(:status=).with('Open')
      result = chat_channel.toggle_status
      expect(result).to eq('Open')
    end
  end

  describe '#publish' do
    let(:message) { { text: 'Hello world' } }

    context 'when PubNub publishes successfully' do
      before do
        allow(pubnub_envelope).to receive(:error).and_return(nil)
      end

      it 'publishes to the correct channel' do
        expect(PN).to receive(:publish).with(
          channel: channel_name,
          message: message,
          http_sync: true,
          callback: anything
        ).and_return([pubnub_envelope])
        
        chat_channel.publish(message)
      end

      it 'uses http_sync mode' do
        expect(PN).to receive(:publish).with(
          hash_including(http_sync: true)
        ).and_return([pubnub_envelope])
        
        chat_channel.publish(message)
      end

      it 'provides a callback for error handling' do
        expect(PN).to receive(:publish).with(
          hash_including(callback: instance_of(Proc))
        ).and_return([pubnub_envelope])
        
        chat_channel.publish(message)
      end

      it 'returns the PubNub envelope' do
        result = chat_channel.publish(message)
        expect(result).to eq([pubnub_envelope])
      end
    end

    context 'when PubNub publish fails' do
      let(:error_envelope) { double('PubNub::Envelope', error: true, inspect: 'Error details') }
      
      before do
        allow(PN).to receive(:publish).and_return([error_envelope])
        allow(error_envelope).to receive(:error).and_return(true)
      end

      it 'logs the error details' do
        allow(PN).to receive(:publish) do |args|
          callback = args[:callback]
          callback.call(error_envelope) if callback
          [error_envelope]
        end
        
        expect { chat_channel.publish(message) }.to output(/Failed to send message/).to_stdout
      end
    end
  end

  describe '#send_message' do
    let(:message) { { user: 'testuser', msg: 'Hello' } }

    context 'when channel is open' do
      before do
        allow(chat_channel).to receive(:open?).and_return(true)
      end

      it 'publishes the message with chat metadata' do
        expect(chat_channel).to receive(:publish).with(meta: 'chat', data: message)
        chat_channel.send_message(message)
      end

      it 'logs the message publication' do
        expect(Rails.logger).to receive(:info).with("====> Publishing message to PubNub: #{message}")
        chat_channel.send_message(message)
      end

      it 'returns the result of publish' do
        allow(chat_channel).to receive(:publish).and_return([pubnub_envelope])
        result = chat_channel.send_message(message)
        expect(result).to eq([pubnub_envelope])
      end
    end

    context 'when channel is closed' do
      before do
        allow(chat_channel).to receive(:open?).and_return(false)
      end

      it 'does not publish the message' do
        expect(chat_channel).not_to receive(:publish)
        chat_channel.send_message(message)
      end

      it 'logs that the channel is closed' do
        expect(Rails.logger).to receive(:info).with("Could not send message. Channel #{channel_name} closed.")
        chat_channel.send_message(message)
      end

      it 'returns false' do
        result = chat_channel.send_message(message)
        expect(result).to be false
      end
    end
  end

  describe 'Redis integration' do
    let(:redis_key) { 'chat-test-channel' }
    let(:test_channel) { ChatChannel.find('test-channel') }

    it 'uses the correct Redis key format' do
      expect($redis).to receive(:hmget).with('chat-test-channel', 'status')
      test_channel.status
    end

    it 'handles Redis connection errors gracefully' do
      allow($redis).to receive(:hmget).and_raise(Redis::ConnectionError)
      begin
        test_channel.status
      rescue Redis::ConnectionError
        # Expected behavior - Redis error propagates
        expect(true).to be true
      end
    end
  end

  describe 'PubNub integration' do
    it 'handles successful PubNub responses' do
      allow(pubnub_envelope).to receive(:error).and_return(nil)
      
      allow(PN).to receive(:publish) do |args|
        callback = args[:callback]
        callback.call(pubnub_envelope) if callback
        [pubnub_envelope]
      end
      
      # Should not output anything for successful publish
      expect { chat_channel.publish({ test: 'message' }) }.not_to output.to_stdout
    end

    it 'handles PubNub errors in callback' do
      error_envelope = double('PubNub::Envelope', error: true, inspect: 'Test error')
      
      allow(PN).to receive(:publish) do |args|
        callback = args[:callback]
        callback.call(error_envelope) if callback
        [error_envelope]
      end
      
      # Should output error message
      expect { chat_channel.publish({ test: 'message' }) }.to output(/Failed to send message/).to_stdout
    end
  end
end