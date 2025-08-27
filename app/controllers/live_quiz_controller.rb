# coding: utf-8

class LiveQuizController < ApplicationController

  before_action :authenticate_user!, :only => :live_quiz

  #-----------------------------------------------------------------------------------------------------------
  # Setup quiz room when user arrives
  #
  # Weekly Wednesday/Saturday quiz will use ID=1
  #-----------------------------------------------------------------------------------------------------------
  def live_quiz

    @tab = "quiz"
    @sub = "livequiz"

    # Redirect users who haven't chosen a translation
    if current_user.translation.nil?
      flash[:notice] = "Please choose a translation and then return to the quiz."
      redirect_to update_profile_path and return
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

    # Feature flag for modern quiz interface
    # Can be controlled via environment variable or user preference
    use_modern_interface = ENV.fetch('USE_MODERN_QUIZ_INTERFACE', 'false') == 'true' ||
                          params[:modern] == 'true' ||
                          current_user.admin? && params[:modern] != 'false'
    
    if use_modern_interface
      render 'live_quiz_modern'
    else
      render 'live_quiz'
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

    # Extract parameters
    quiz_id = params[:quiz_id] || 1  # Default to knowledge quiz
    usr_id = params[:usr_id].to_i
    usr_name = params[:usr_name]
    usr_login = params[:usr_login]
    qq_id = params[:question_id]  # ID of Quiz Question
    question_num = params[:question_num].to_i
    score = params[:score]        # Score out of 10

    # Initialize QuizSession service
    quiz_session = QuizSession.new(quiz_id)
    
    # Add participant if not already added (even with zero score)
    quiz_session.add_participant(usr_id, usr_name, usr_login)
    
    if score != "false" && score.to_i > 0
      # Update user's score
      quiz_session.update_score(usr_id, question_num, score.to_i)
      
      # Update question statistics
      quiz_session.update_question_stats(question_num, qq_id)
    else
      Rails.logger.info("*** Score was submitted as false or zero for #{usr_name}")
      # Update question statistics even for incorrect answers
      quiz_session.update_question_stats(question_num, qq_id)
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
    @till = @quiz.start_time - Time.now # Remaining time in seconds

    if @till >= 0

      # Calculate time left in HH:MM:SS
  	  hours   = (@till/3600).to_i
  	  minutes = (@till/60 - hours * 60).to_i
  	  seconds = (@till - (minutes * 60 + hours * 3600)).to_i

      render :json => {:time => "+#{hours}h +#{minutes}m +#{seconds}s"}

    elsif $redis.exists?("quiz-#{@quiz.id}") && status = $redis.hmget("quiz-#{@quiz.id}", "status").first

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
