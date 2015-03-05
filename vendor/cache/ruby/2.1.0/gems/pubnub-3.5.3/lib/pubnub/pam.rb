module Pubnub
  module PAM
    def initialize(options, app)
      super
      @auth_key = options[:auth_key]
    end

    def signature(app)
      channel = @original_channel.first
      message = "#{@subscribe_key}\n#{@publish_key}\n#{@event}\n#{variables_for_signature(app)}"
      Base64.urlsafe_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), @secret_key.to_s, message)).strip
    end

    def payload(parsed_response)
      parsed_response['payload'] if parsed_response
    end

    def message(parsed_response)
      parsed_response['message'] if parsed_response
    end

    def channel(parsed_response)
      @channel.first
    end

    def parameters(app, signature = false)
      params = super(app)
      params.merge!({ :timestamp => @timestamp })
      params.merge!({ :channel   => @channel.first })
      params.merge!({ :signature => signature(app) }) unless signature
      params
    end

    def variables_for_signature(app)
      parameters(app, true).map{|k,v|
        "#{k.to_s}=#{CGI.escape(v.to_s).gsub('+','%20')}"
      }.sort.join('&')
    end

    def current_time
      ::Time.now.to_i
    end

    def format_envelopes(response, app, error)

      parsed_response = Parser.parse_json(response.body) if Parser.valid_json?(response.body)

      envelopes = Array.new
      envelopes << Envelope.new(
          {
              :payload => payload(parsed_response),
              :message => message(parsed_response),
              :channel => channel(parsed_response)
          },
          app
      )

      envelopes = add_common_data_to_envelopes(envelopes, response, app, error)

      envelopes

    end
  end
end