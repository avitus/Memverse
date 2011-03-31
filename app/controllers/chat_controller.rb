require "juggernaut"

class ChatController < ApplicationController
	
	before_filter :login_required
	
  # ----------------------------------------------------------------------------------------------------------
  # Push message to node.js server via Juggernaut
  # ---------------------------------------------------------------------------------------------------------- 	
	def send_message		
	  @messg = params[:msg_body]
	  @sender = params[:sender]
 	  Juggernaut.publish(select_channel("/channel1"), parse_chat_message(params[:msg_body], params[:sender]))	
	  respond_to do |format|
	    format.js
  	end
	end
	
	# Not working ...
	def update_roster
		Juggernaut.subscribe do |event, data|
		  logger.debug("Event: #{event.inspect}, Data: #{data.inspect}")
		end	
	end
	

	def parse_chat_message(msg, user)
	  return "#{user}: #{msg}"
	end

	def select_channel(receiver)
	  puts "#{receiver}"
	  return "/chats#{receiver}"
	end
end
