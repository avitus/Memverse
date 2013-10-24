class ChatController < ApplicationController

  before_filter :authenticate_user!, :only => :channel1

  # ----------------------------------------------------------------------------------------------------------
  # Open/close chat channel
  # ----------------------------------------------------------------------------------------------------------
  def toggle_channel

    channel = params[:channel] || "channel1"
    if $redis.exists("chat-#{channel}")
      status = $redis.hmget("chat-#{channel}", "status").first
    end

    new_status = (status && status == "Open") ? "Closed":"Open"

    $redis.hset("chat-#{channel}", "status", new_status)

    @my_callback = lambda { |message| puts(message) } # for PubNub

    PN.publish(
        :channel  => channel,
        :message  => {
          :meta => "chat_status",
          :status => new_status
        },
        :callback => @my_callback
      )

    render :json => {:status => new_status}
  end

  # ----------------------------------------------------------------------------------------------------------
  # Globally toggle ban of user from chat with redis key
  # ----------------------------------------------------------------------------------------------------------
  def toggle_ban
    user_id = params[:user_id]

    if user_id && current_user.admin?
      if $redis.exists("banned-#{user_id}")
        $redis.del("banned-#{user_id}")
        status = "Ban revoked"
      else
        $redis.set("banned-#{user_id}","banned")
        status = "Banned"
      end
    end

    render :json => {:status => status}
  end

  # ----------------------------------------------------------------------------------------------------------
  # Publish message to PubNub
  # ----------------------------------------------------------------------------------------------------------
  def send_message

    @msg 		= params[:msg_body]
    @usr 		= params[:sender]
    @usr_id = params[:user_id]
    channel = params[:channel] || "channel1"

    chat_open  = $redis.exists("chat-#{channel}") ? ($redis.hmget("chat-#{channel}", "status").first == "Open") : true
    usr_banned = $redis.exists("banned-#{@usr_id}")

    @my_callback = lambda { |message| puts(message) } # for PubNub

    if chat_open && !usr_banned # Check that chat is open and user is not banned
      PN.publish( :channel  => channel, :message  => {
          :meta => "chat",
          :data => parse_chat_message(params[:msg_body], params[:sender], params[:user_id])
        },
        :callback => @my_callback
      )
    end

    respond_to do |format|
      format.js
   end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Split message into user id, name, and message
  # ----------------------------------------------------------------------------------------------------------
  def parse_chat_message(msg, user, user_id=nil) # user_id may be nil if annnouncement is from server
    return "#{user_id}:#{user}: #{msg}"
  end

end
