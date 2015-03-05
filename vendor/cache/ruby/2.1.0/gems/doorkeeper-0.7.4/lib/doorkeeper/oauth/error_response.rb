module Doorkeeper
  module OAuth
    class ErrorResponse
      include Doorkeeper::OAuth::Authorization::URIBuilder

      def self.from_request(request, attributes = {})
        state = request.state if request.respond_to?(:state)
        new(attributes.merge(:name => request.error, :state => state))
      end

      delegate :name, :description, :state, :to => :@error

      def initialize(attributes = {})
        @error = Doorkeeper::OAuth::Error.new(*attributes.values_at(:name, :state))
        @redirect_uri = attributes[:redirect_uri]
        @response_on_fragment = attributes[:response_on_fragment]
      end

      def body
        { :error => name, :error_description => description, :state => state }.reject { |k, v| v.blank? }
      end

      def status
        :unauthorized
      end

      def redirectable?
        (name != :invalid_redirect_uri) && (name != :invalid_client)
      end

      def redirect_uri
        if @response_on_fragment
          uri_with_fragment @redirect_uri, body
        else
          uri_with_query @redirect_uri, body
        end
      end

      def headers
        { 'Cache-Control' => 'no-store', 'Pragma' => 'no-cache', 'Content-Type' => 'application/json; charset=utf-8' }
      end
    end
  end
end
