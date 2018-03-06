PN = Pubnub.new(
    publish_key:   Rails.application.secrets[:pubnub_publish],   # publish_key only required if publishing.
    subscribe_key: Rails.application.secrets[:pubnub_subscribe], # required
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
