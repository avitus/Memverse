module Doorkeeper
  module Request
    class Token
      # TODO: this is so wrong!
      def self.build(server)
        new(server.context.send(:pre_auth), server)
      end

      attr_accessor :pre_auth, :server

      def initialize(pre_auth, server)
        @pre_auth, @server = pre_auth, server
      end

      def request
        @request ||= OAuth::TokenRequest.new(pre_auth, server.current_resource_owner)
      end

      def authorize
        request.authorize
      end
    end
  end
end
