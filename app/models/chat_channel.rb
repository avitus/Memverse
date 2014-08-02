class ChatChannel

  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  def self.find(channel = "channel1")
    new(channel)
  end

  def status
    $redis.hmget("chat-#{channel}", "status").try(:first) || "Closed"
  end

  def status=(new_status)
    return if new_status == status

    $redis.hset("chat-#{channel}", "status", new_status)

    publish(meta: "chat_status", status: new_status)
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

  def send_message(msg)
    if open?
      Rails.logger.info("====> Publishing message to PubNub: #{msg}")
      publish(meta: "chat", data: msg)
    else
      puts "Could not send message. Channel #{channel} closed."
      return false
    end
  end

end
