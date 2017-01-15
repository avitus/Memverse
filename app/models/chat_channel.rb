class ChatChannel

  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  # Return given ChatChannel
  # @param channel [String]
  # @return [ChatChannel]
  def self.find(channel = "channel1")
    new(channel)
  end

  # Status of channel
  # @return [String]
  def status
    $redis.hmget("chat-#{channel}", "status").try(:first) || "Closed"
  end

  # Update channel status in Redis and publish change
  # @param new_status [String]
  # @return [void]
  def status=(new_status)
    return if new_status == status

    $redis.hset("chat-#{channel}", "status", new_status)

    publish(meta: "chat_status", status: new_status)
  end

  # Is channel open?
  # @return [Boolean]
  def open?
    status == "Open"
  end

  # Is channel closed?
  # @return [Boolean]
  def closed?
    status == "Closed"
  end

  # Change channel status
  # @see #status=
  # @return [String] New status ("Closed" or "Open")
  def toggle_status
    self.status = open? ? "Closed":"Open"
  end


  # Publish message to channel via PubNub
  # @param msg [String]
  # @return [Array<PubNub::Envelope>]
  def publish(msg)
    callback = lambda { |envelope|
      if envelope.error
        # If message is not sent we should probably try to send it again
        puts("==== ! Failed to send message ! ==========")
        puts( envelope.inspect )
      end
    }

    PN.publish(
      channel: channel,
      message: msg,
      http_sync: true,
      callback: callback
    )
  end

  # Publish a chat message, assuming channel is open.
  # @see #publish
  # @param msg [String]
  # @return [Array<PubNub::Envelope>, false] False indicates closed channel.
  def send_message(msg)
    if open?
      Rails.logger.info("====> Publishing message to PubNub: #{msg}")
      publish(meta: "chat", data: msg)
    else
      Rails.logger.info("Could not send message. Channel #{channel} closed.")
      return false
    end
  end

end
