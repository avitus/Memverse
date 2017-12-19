class ChatController < ApplicationController

  before_action :authenticate_user!, :only => [:channel1, :toggle_ban, :index]

  #-----------------------------------------------------------------------------------------------------------
  # Main chat room
  #-----------------------------------------------------------------------------------------------------------
  def index

    @tab = "blog"
    @sub = "chat"

    channel_num = params[:channel] || 7
    @channel    = ChatChannel.find("chat-#{channel_num}")
    puts @channel
    puts channel_num

  end


  # ----------------------------------------------------------------------------------------------------------
  # Open/close chat channel
  # ----------------------------------------------------------------------------------------------------------
  def toggle_channel

    channel = ChatChannel.find(params[:channel])

    Rails.logger.info("Located chat channel: #{channel}")

    new_status = channel.toggle_status

    Rails.logger.info("Channel is now #{new_status}")

    render :json => {:status => new_status}
  end

  # ----------------------------------------------------------------------------------------------------------
  # Globally toggle ban of user from chat with redis key
  # ----------------------------------------------------------------------------------------------------------
  def toggle_ban
    user_id = params[:user_id]

    if user_id && (can? :manage, Quiz)
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
    channel = ChatChannel.find(params[:channel])

    banned  = $redis.exists("banned-#{@usr_id}")

    if !banned
      channel.send_message(parse_chat_message(@msg, @usr, @usr_id))
    else
      puts "Could not send message. User #{@usr_id} is banned."
    end

    respond_to do |format|
      format.js
   end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Split message into user id, name, and message
  # ----------------------------------------------------------------------------------------------------------
  def parse_chat_message(msg, user, user_id=nil) # user_id may be nil if announcement is from server
    {user: user, user_id: user_id, msg: msg}
  end

end
