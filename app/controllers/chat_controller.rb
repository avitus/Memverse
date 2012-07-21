require "juggernaut"

class ChatController < ApplicationController

  before_filter :authenticate_user!, :only => :channel1

  # ----------------------------------------------------------------------------------------------------------
  # View chat channel 1
  # ---------------------------------------------------------------------------------------------------------- 	
  def channel1
  end

  # ----------------------------------------------------------------------------------------------------------
  # Open/close chat channel
  # ---------------------------------------------------------------------------------------------------------- 	
  
  def toggle_channel
    channel = params[:channel] || "channel1"
    if $redis.exists("chat-#{channel}")
      status = $redis.hmget("chat-#{channel}", "status").first
    end

    new_status = (status && status == "Open")?"Closed":"Open"

    $redis.hset("chat-#{channel}", "status", new_status)
    Juggernaut.publish(select_channel(channel), {:status => new_status})

    render :json => {:status => new_status}
  end

  # ----------------------------------------------------------------------------------------------------------
  # Push message to node.js server via Juggernaut
  # ---------------------------------------------------------------------------------------------------------- 	
  def send_message		
    @msg 		= params[:msg_body]
    @usr 		= params[:sender]
    channel = params[:channel] || "channel1"
    if $redis.exists("chat-#{channel}") && $redis.hmget("chat-#{channel}", "status").first == "Open"
      Juggernaut.publish(select_channel(channel), parse_chat_message(params[:msg_body], params[:sender])) unless @msg.blank?
    end
    respond_to do |format|
      format.js
   end
  end

  def parse_chat_message(msg, user)
    return "#{user}: #{msg}"
  end

  def select_channel(receiver)
    puts "#{receiver}"
    return "/chats/#{receiver}"
  end
end
