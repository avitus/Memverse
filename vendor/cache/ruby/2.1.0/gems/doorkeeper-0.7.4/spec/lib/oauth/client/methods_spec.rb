require 'spec_helper'
require 'active_support/core_ext/string'
require 'doorkeeper/oauth/client'

class Doorkeeper::OAuth::Client
  describe 'Methods' do
    let(:client_id) { "some-uid" }
    let(:client_secret) { "some-secret" }

    subject do
      Class.new do
        include Methods
      end.new
    end

    describe :from_params do
      it 'returns credentials from parameters when Authorization header is not available' do
        request     = stub :parameters => { :client_id => client_id, :client_secret => client_secret }
        uid, secret = subject.from_params(request)

        uid.should    == "some-uid"
        secret.should == "some-secret"
      end

      it 'is blank when there are no credentials' do
        request     = stub :parameters => {}
        uid, secret = subject.from_params(request)

        uid.should    be_blank
        secret.should be_blank
      end
    end

    describe :from_basic do
      let(:credentials) { Base64.encode64("#{client_id}:#{client_secret}") }

      it 'decodes the credentials' do
        request     = stub :authorization => "Basic #{credentials}"
        uid, secret = subject.from_basic(request)

        uid.should    == "some-uid"
        secret.should == "some-secret"
      end

      it 'is blank if Authorization is not Basic' do
        request     = stub :authorization => "#{credentials}"
        uid, secret = subject.from_basic(request)

        uid.should    be_blank
        secret.should be_blank
      end
    end
  end
end
