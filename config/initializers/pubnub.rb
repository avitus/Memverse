if Rails.env.development?

  PN = Pubnub.new(
      :publish_key   => 'pub-c-56b243c5-5d07-457a-a290-fa4a29b1ff83', # publish_key only required if publishing.
      :subscribe_key => 'sub-c-88c2a812-47e6-11e3-8c4f-02ee2ddab7fe', # required
      :secret_key    => nil,    # optional, if used, message signing is enabled
      :cipher_key    => nil,    # optional, if used, encryption is enabled
      :ssl           => true    # true or default is false
  )

else

  # Use production key by default
  PN = Pubnub.new(
      :publish_key   => 'pub-c-dc9e4561-d42a-4270-84b9-a9f268cd2cd2', # publish_key only required if publishing.
      :subscribe_key => 'sub-c-bcc87aee-e8b7-11e2-acbe-02ee2ddab7fe', # required
      :secret_key    => nil,    # optional, if used, message signing is enabled
      :cipher_key    => nil,    # optional, if used, encryption is enabled
      :ssl           => true    # true or default is false
  )

end
