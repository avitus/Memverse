module Doorkeeper
  module OAuth
    class PreAuthorization
      include Doorkeeper::Validations

      validate :response_type, :error => :unsupported_response_type
      validate :client, :error => :invalid_client
      validate :scopes, :error => :invalid_scope
      validate :redirect_uri, :error => :invalid_redirect_uri

      attr_accessor :server, :client, :response_type, :redirect_uri, :state
      attr_writer   :scope

      def initialize(server, client, attrs = {})
        @server        = server
        @client        = client
        @response_type = attrs[:response_type]
        @redirect_uri  = attrs[:redirect_uri]
        @scope         = attrs[:scope]
        @state         = attrs[:state]
      end

      def authorizable?
        valid?
      end

      def scopes
        Scopes.from_string scope
      end

      def scope
        @scope.presence || server.default_scopes.to_s
      end

      def error_response
        Doorkeeper::OAuth::ErrorResponse.from_request(self)
      end

    private

      def validate_response_type
        %w[code token].include? response_type
      end

      def validate_client
        client.present?
      end

      def validate_scopes
        return true unless scope.present?
        Helpers::ScopeChecker.valid? scope, server.scopes
      end

      # TODO: test uri should be matched against the client's one
      def validate_redirect_uri
        return false unless redirect_uri.present?
        Helpers::URIChecker.test_uri?(redirect_uri) ||
        Helpers::URIChecker.valid_for_authorization?(redirect_uri, client.redirect_uri)
      end
    end
  end
end
