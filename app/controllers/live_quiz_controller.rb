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

    quiz_id = (params[:quiz] || 1).to_i

    @quiz = Quiz.find(quiz_id)

    @quiz_master = @quiz.user

    # Check status of chat channel
    @channel = ChatChannel.find("quiz-#{@quiz.id}")
    
    # Check if quiz is currently running
    quiz_session = QuizSession.new(@quiz.id)
    @quiz_running = quiz_session.quiz_in_progress?

    # Check if quiz is in preparing/initializing state
    quiz_status = quiz_session.get_quiz_status
    # Consider quiz as preparing if it's in any initialization state
    @quiz_preparing = quiz_status.to_s.include?("Initializing") ||
                      quiz_status == "In progress. Chat opening soon." ||
                      quiz_status == "In progress. Chat open. Wait for question."


    # Get next scheduled quiz time if quiz is not running
    unless @quiz_running
      if @quiz.id.to_i == 1  # Knowledge quiz uses cron schedule
        @next_quiz_time = Quiz.next_knowledge_quiz_time
        @quiz_schedule = Quiz.knowledge_quiz_schedule
      elsif @quiz.start_time && @quiz.start_time > Time.current
        @next_quiz_time = @quiz.start_time
      end
    end

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

    # Render the quiz view
    # Feature flag: Use legacy view only if explicitly requested
    if params[:legacy] == 'true'
      render 'live_quiz'
    else
      render 'live_quiz_modern'
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

    # For knowledge quiz (ID=1), check if it's currently running using QuizSession
    if @quiz.id == 1
      quiz_session = QuizSession.new(@quiz.id)
      current_status = quiz_session.get_quiz_status

      if current_status && current_status.include?("progress")
        # Check if we're in the chat period and should show a countdown
        if current_status == "In progress. Chat open. Wait for question."
          metadata = quiz_session.get_quiz_metadata

          if metadata["chat_start_time"] && metadata["chat_duration"]
            chat_start = Time.parse(metadata["chat_start_time"])
            chat_duration = metadata["chat_duration"].to_i
            chat_end = chat_start + chat_duration
            remaining_seconds = (chat_end - Time.current.utc).to_i

            if remaining_seconds > 0
              # Return countdown info for chat period
              render :json => {
                :status => current_status,
                :chat_countdown => true,
                :countdown_seconds => remaining_seconds
              }
            else
              # Chat period is over, just return status
              render :json => {:status => current_status}
            end
          else
            # No chat timing info, just return status
            render :json => {:status => current_status}
          end
        else
          # Quiz is in progress but not in chat period
          render :json => {:status => current_status}
        end
      else
        # Quiz is not running, return "Finished" or similar
        render :json => {:status => "Finished"}
      end
    else
      # For other quizzes, use start_time if available
      if @quiz.start_time
        @till = @quiz.start_time - Time.current # Remaining time in seconds

        if @till >= 0
          # Calculate time left in HH:MM:SS
          hours   = (@till/3600).to_i
          minutes = (@till/60 - hours * 60).to_i
          seconds = (@till - (minutes * 60 + hours * 3600)).to_i

          render :json => {:time => "+#{hours}h +#{minutes}m +#{seconds}s"}
        else
          # Check quiz status using QuizSession service
          quiz_session = QuizSession.new(@quiz.id)
          current_status = quiz_session.get_quiz_status

          if current_status
            # Check if we're in the chat period for non-knowledge quizzes too
            if current_status == "In progress. Chat open. Wait for question."
              metadata = quiz_session.get_quiz_metadata

              if metadata["chat_start_time"] && metadata["chat_duration"]
                chat_start = Time.parse(metadata["chat_start_time"])
                chat_duration = metadata["chat_duration"].to_i
                chat_end = chat_start + chat_duration
                remaining_seconds = (chat_end - Time.current.utc).to_i

                if remaining_seconds > 0
                  # Return countdown info for chat period
                  render :json => {
                    :status => current_status,
                    :chat_countdown => true,
                    :countdown_seconds => remaining_seconds
                  }
                else
                  # Chat period is over, just return status
                  render :json => {:status => current_status}
                end
              else
                # No chat timing info, just return status
                render :json => {:status => current_status}
              end
            else
              render :json => {:status => current_status}
            end
          else
            render :json => {:status => "Finished"}
          end
        end
      else
        # No start time, check if quiz is in progress
        quiz_session = QuizSession.new(@quiz.id)
        current_status = quiz_session.get_quiz_status

        if current_status && current_status.include?("progress")
          render :json => {:status => current_status}
        else
          render :json => {:status => "Finished"}
        end
      end
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
