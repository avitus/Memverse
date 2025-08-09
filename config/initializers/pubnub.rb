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
   ssl:           true,                                         # true or default is false
   logger:        pubnub_logger,                                # use the standard logger
   user_id:       'memverse_user'                               # static user_id for compatibility
)

PN_CALLBACK = lambda { |envelope|
  if envelope.error
    # if message is not sent we should probably try to send it again
    puts("==== ! Failed to send message ! ==========")
    puts( envelope.inspect )
  end
}
