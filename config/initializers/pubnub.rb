PN = Pubnub.new(
    # These are the regular PubNub Memverse keys. The /chat page uses the ChatEngine keys
    publish_key:   'pub-c-dc9e4561-d42a-4270-84b9-a9f268cd2cd2', # publish_key only required if publishing.
    subscribe_key: 'sub-c-bcc87aee-e8b7-11e2-acbe-02ee2ddab7fe', # required
    secret_key:    nil,                                          # optional, if used, message signing is enabled
    cipher_key:    nil,                                          # optional, if used, encryption is enabled
    ssl:           true,                                         # true or default is false
    logger:        Logger.new('log/pubnub.log', 'monthly')       # use the standard logger
)

PN_CALLBACK = lambda { |envelope|
  if envelope.error
    # if message is not sent we should probably try to send it again
    puts("==== ! Failed to send message ! ==========")
    puts( envelope.inspect )
  end
}
