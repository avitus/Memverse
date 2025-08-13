# Create a logger adapter that works with both Pubnub and Concurrent
class PubnubLoggerAdapter < Logger
  def initialize(*args)
    super
  end
  
  # Make the logger callable for Concurrent.global_logger
  def call(level, progname, message = nil, &block)
    add(level, message, progname, &block)
  end
end

# Create a logger instance that works with both Pubnub and Concurrent
pubnub_logger = PubnubLoggerAdapter.new('log/pubnub.log', 'monthly')

PN = Pubnub.new(
   # These are the regular PubNub Memverse keys. The /chat page uses the ChatEngine keys
   publish_key:   'pub-c-dc9e4561-d42a-4270-84b9-a9f268cd2cd2', # publish_key only required if publishing.
   subscribe_key: 'sub-c-bcc87aee-e8b7-11e2-acbe-02ee2ddab7fe', # required
   secret_key:    nil,                                          # optional, if used, message signing is enabled
   cipher_key:    nil,                                          # optional, if used, encryption is enabled
   ssl:           true,                                         # SSL enabled for security
   logger:        pubnub_logger,                                # use the standard logger
   user_id:       'memverse_server',                            # unique user_id for server (updated from uuid)
   retry_configuration: {
     retries_after_network_failure: 3,                         # retry 3 times on network failure
     retry_delay_on_network_failure: 1.0                       # wait 1 second between retries
   },
   heartbeat:     30,                                           # send heartbeat every 30 seconds
   presence_timeout: 60                                         # consider user offline after 60 seconds
)

# Enhanced callback function with better error handling
PN_CALLBACK = lambda { |envelope|
  if envelope.error
    Rails.logger.error("PubNub Error: #{envelope.error_message}")
    Rails.logger.error("Error details: #{envelope.inspect}")
    
    # Log specific error categories for debugging
    case envelope.status
    when 403
      Rails.logger.error("PubNub: Access denied - check publish/subscribe keys")
    when 400
      Rails.logger.error("PubNub: Bad request - check message format")
    when 0, nil
      Rails.logger.error("PubNub: Network connectivity issue")
    else
      Rails.logger.error("PubNub: Unknown error with status: #{envelope.status}")
    end
  else
    Rails.logger.debug("PubNub message sent successfully: #{envelope.timetoken}")
  end
}
