PN = Pubnub.new(
    :publish_key   => 'pub-c-dc9e4561-d42a-4270-84b9-a9f268cd2cd2', # publish_key only required if publishing.
    :subscribe_key => 'sub-c-bcc87aee-e8b7-11e2-acbe-02ee2ddab7fe', # required
    :secret_key    => nil,    # optional, if used, message signing is enabled
    :cipher_key    => nil,    # optional, if used, encryption is enabled
    :ssl           => nil     # true or default is false
)