class ChatChannel

  attr_reader :channel

  # PubNub callback
  PN_callback = lambda { |envelope|
    if envelope.error
      # If message is not sent we should probably try to send it again
      puts("==== ! Failed to send message ! ==========")
      puts( envelope.inspect )
    end
  }

  def initialize(channel)
    @channel = channel
  end

  def self.find(channel = "channel1")
    new(channel)
  end

  def status
    $redis.hmget("chat-#{channel}", "status").try(:first) || "Closed"
  end

  def status=(str)
    $redis.hset("chat-#{channel}", "status", str)

    PN.publish(
      channel: channel,
      message: {
        meta: "chat_status",
        status: str
      },
      http_sync: true,
      callback: PN_callback
    )
  end

  def open?
    status == "Open"
  end

  def closed?
    status == "Closed"
  end

  def toggle_status
    self.status = open? ? "Closed":"Open"
  end

  def send_message(msg)
    if open?
      Rails.logger.info("====> Publishing message to PubNub: #{msg}")
      PN.publish(
        channel: channel,
        message: {
          meta: "chat",
          data: msg
        },
        http_sync: true,
        callback: PN_callback
      )
    else
      puts "Could not send message. Channel #{channel} closed."
      return false
    end
  end

end
