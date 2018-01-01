# coding: utf-8

class LiveQuizController < ApplicationController

  before_action :authenticate_user!, :only => :live_quiz

  #-----------------------------------------------------------------------------------------------------------
  # Setup quiz room when user arrives
  #
  # Weekly Wednesday quiz will use ID=1
  #-----------------------------------------------------------------------------------------------------------
  def live_quiz

    @tab = "quiz"
    @sub = "livequiz"

    # Redirect users who haven't chosen a translation
    if current_user.translation.nil?
      flash[:notice] = "Please choose a translation and then return to the quiz."
      redirect_to update_profile_path
    end

    @quiz = Quiz.find(params[:quiz] || 1 )
    @quiz_master = @quiz.user

    # Check status of chat channel
    @channel = ChatChannel.find("quiz-#{@quiz.id}")

    # Set up quiz time and number of questions - show when user first enters quiz room
    if @quiz.id == 1
      @minutes       =  20
      @seconds       =  0
      @num_questions =  25
    elsif @quiz.quiz_length.nil?
      flash[:notice] = "That quiz is not ready yet."
      redirect_to root_path and return
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

    # Redis keys
    usr_id      = "user-" + params[:usr_id].to_s
    q_num       = "qnum-" + params[:question_num].to_s # Question number in Quiz

    usr_name    = params[:usr_name]
    usr_login   = params[:usr_login]
    qq_id       = params[:question_id]  # ID of Quiz Question
    score       = params[:score]        # Score out of 10

    if score != "false"

      # Update user scores. Store the score in Redis store
      $redis.hincrby(usr_id, 'score', score)
      # Capture user's name and login if we don't have them
      $redis.hmset(usr_id, 'name', usr_name, 'login', usr_login, 'id', params[:usr_id].to_s)

      # Update question difficulty
      $redis.hincrby(q_num, 'total_score', score)  # Add user's score to combined score for that question
      $redis.hincrby(q_num, 'answered', 1)         # Increment count for that quiz
      $redis.hsetnx(q_num, 'qq_id', qq_id)         # Store QuizQuestion ID if we don't have it yet

    else

      Rails.logger.info("*** Score was submitted as false for #{usr_name}")

    end

    respond_to do |format|
      format.all { head :ok }
    end

  end

  #-----------------------------------------------------------------------------------------------------------
  # Return time till quiz starts
  #-----------------------------------------------------------------------------------------------------------
  def till_start

    @quiz = Quiz.find(params[:id] || 1)
    @till = @quiz.start_time - Time.now + 300 # Remaining time in seconds, including chat time

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
  # Used for load testing
  #-----------------------------------------------------------------------------------------------------------
  def test_sign_in_random
    sign_in(:user, User.find_by_email("student#{rand(50)}@sttsetia.org"))
    redirect_to "/live_quiz?quiz=16"
  end

end
