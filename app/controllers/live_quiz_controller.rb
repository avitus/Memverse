# coding: utf-8

require "juggernaut"

class LiveQuizController < ApplicationController

  before_filter :authenticate_user!, :only => :live_quiz

  #-----------------------------------------------------------------------------------------------------------
  # Setup quiz room when user arrives
  #-----------------------------------------------------------------------------------------------------------
  def live_quiz

    # Redirect users who haven't chosen a translation
    if current_user.translation.nil?
      flash[:notice] = "Please choose a translation and then return to the quiz."
      redirect_to update_profile_path
    end

    @quiz = Quiz.find(params[:quiz] || 1 )
    @quiz_master = @quiz.user

    # Check status of chat channel
    @chat_status = ($redis.exists("chat-quiz-#{@quiz.id}") && $redis.hmget("chat-quiz-#{@quiz.id}", "status").first == "Open") ? "Open" : "Closed"

    # Set up quiz time and number of questions - show when user first enters quiz room
    if @quiz.id == 1
      @minutes       =  5
      @seconds       =  0
      @num_questions =  10
    else
      @minutes       =  @quiz.quiz_length / 60
      @seconds       =  @quiz.quiz_length - (@minutes * 60)
      @num_questions =  @quiz.quiz_questions.length
    end

  end

  #-----------------------------------------------------------------------------------------------------------
  # Parse questions for quiz presentation
  #-----------------------------------------------------------------------------------------------------------
  def parse_quiz_question(num, type, passage)
    return "#{num}: #{passage} (#{type.capitalize})"
  end

  #-----------------------------------------------------------------------------------------------------------
  # Select channel
  #-----------------------------------------------------------------------------------------------------------
  def select_channel(receiver)
    puts "#{receiver}"
    return "/live_quiz#{receiver}"
  end

  #-----------------------------------------------------------------------------------------------------------
  # This method receive scores for each participant
  #-----------------------------------------------------------------------------------------------------------
  def record_score
    usr_id    = "user-" + params[:usr_id].to_s
    usr_name  = params[:usr_name]
    usr_login = params[:usr_login]
    score     = params[:score]

    if score != "false"
      # Store the score in Redis store
      $redis.hincrby(usr_id, 'score', score)
      $redis.hmset(usr_id, 'name', usr_name, 'login', usr_login)
    else
      Rails.logger.info("*** Score was submitted as false for #{usr_name}")
    end

    respond_to do |format|
      format.all { render :nothing => true, :status => 200 }
    end

  end

  #-----------------------------------------------------------------------------------------------------------
  # This method publishes the scoreboard
  # Format: [{"score"=>"11", "name"=>"Andy"}, {"score"=>"14", "name"=>"Alex"} ]
  #-----------------------------------------------------------------------------------------------------------
  def publish_scoreboard
  	scoreboard = Array.new

    participants = $redis.keys("user-*")
    participants.each { |p|	scoreboard << $redis.hgetall(p) }

    return scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }
  end

  #-----------------------------------------------------------------------------------------------------------
  # Return the roster via JSON; used for initial roster loading
  #-----------------------------------------------------------------------------------------------------------
  def roster
  	@roster = Roster.all
	  render :json => @roster
  end

  #-----------------------------------------------------------------------------------------------------------
  # Return time till quiz starts
  #-----------------------------------------------------------------------------------------------------------
  def till_start

    @quiz = Quiz.find(params[:id] || 1)
    @till = @quiz.start_time - Time.now # Remaining time in seconds

    if @till >= 0

      # Calculate time left in HH:MM:SS
  	  hours   = (@till/3600).to_i
  	  minutes = (@till/60 - hours * 60).to_i
  	  seconds = (@till - (minutes * 60 + hours * 3600)).to_i

      render :json => {:time => "+#{hours}h +#{minutes}m +#{seconds}s"}

    elsif $redis.exists("quiz-#{@quiz.id}") && status = $redis.hmget("quiz-#{@quiz.id}", "status")

      render :json => {:status => status}

    else

      render :json => {:status => "Finished"}

    end

  end

  #-----------------------------------------------------------------------------------------------------------
  # Used for load testing of Juggernaut
  #-----------------------------------------------------------------------------------------------------------
  def test_sign_in_random
    sign_in(:user, User.find_by_email("student#{rand(50)}@sttsetia.org"))
    redirect_to "/live_quiz?quiz=16"
  end

end
