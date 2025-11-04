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
  # API endpoint for quiz state - Single source of truth for quiz timing
  #-----------------------------------------------------------------------------------------------------------
  def quiz_state
    quiz_id = (params[:id] || params[:quiz_id] || 1).to_i
    quiz = Quiz.find(quiz_id)

    state = calculate_quiz_state(quiz)

    render json: {
      state: state[:state],
      next_transition_at: state[:next_transition_at],
      transition_to: state[:transition_to],
      should_refresh: state[:should_refresh],
      server_time: Time.current.utc.iso8601,
      quiz_id: quiz.id
    }
  end

  private

  def calculate_quiz_state(quiz)
    quiz_session = QuizSession.new(quiz.id)
    current_status = quiz_session.get_quiz_status
    now = Time.current.utc

    # Log for debugging
    Rails.logger.debug "Quiz ##{quiz.id} status: #{current_status.inspect}"

    # Check status first, regardless of quiz type
    if current_status.present? && current_status != "Available"
      # Quiz has an active status
      if current_status.include?("Initializing") || current_status.include?("Chat opening soon")
        # Quiz is initializing
        return {
          state: "preparing",
          next_transition_at: (now + 5.seconds).iso8601, # Check again soon
          transition_to: "ready",
          should_refresh: false
        }
      elsif current_status.include?("Chat open. Wait for question")
        # Quiz is ready, user should refresh if they see the preparing overlay
        return {
          state: "ready",
          should_refresh: user_sees_preparing_overlay?,
          next_transition_at: nil,
          transition_to: "running"
        }
      elsif current_status.include?("Question in progress") || (current_status.include?("In progress") && !current_status.include?("Chat"))
        # Quiz running (question in progress)
        return {
          state: "running",
          should_refresh: false,
          next_transition_at: nil,
          transition_to: "finished"
        }
      elsif current_status == "Finished"
        # Quiz explicitly finished
        return {
          state: "finished",
          should_refresh: false,
          next_transition_at: nil,
          transition_to: nil
        }
      end
    end

    # No active status, check schedule
    if quiz.id == 1
      # Knowledge quiz uses scheduled times
      next_quiz_time = Quiz.next_knowledge_quiz_time

      if next_quiz_time && next_quiz_time > now
        time_until_start = next_quiz_time - now

        if time_until_start <= 5.seconds
          # Worker about to start
          {
            state: "preparing",
            next_transition_at: next_quiz_time.iso8601,
            transition_to: "ready",
            should_refresh: false
          }
        else
          # Waiting for quiz
          {
            state: "waiting",
            next_transition_at: (next_quiz_time - 5.seconds).iso8601,
            transition_to: "preparing",
            should_refresh: false
          }
        end
      else
        # No quiz scheduled or quiz finished
        {
          state: current_status == "Finished" ? "finished" : "none",
          should_refresh: false,
          next_transition_at: nil,
          transition_to: nil
        }
      end
    else
      # Other quizzes use start_time
      if quiz.start_time && quiz.start_time > now
        time_until_start = quiz.start_time - now

        if time_until_start <= 5.seconds
          # Worker about to start
          {
            state: "preparing",
            next_transition_at: quiz.start_time.iso8601,
            transition_to: "ready",
            should_refresh: false
          }
        else
          # Waiting for quiz
          {
            state: "waiting",
            next_transition_at: (quiz.start_time - 5.seconds).iso8601,
            transition_to: "preparing",
            should_refresh: false
          }
        end
      else
        # No quiz scheduled or quiz finished
        {
          state: current_status == "Finished" ? "finished" : "none",
          should_refresh: false,
          next_transition_at: nil,
          transition_to: nil
        }
      end
    end
  end

  def user_sees_preparing_overlay?
    # Check if the request includes a header or parameter indicating the preparing overlay is visible
    # This can be sent by the JavaScript when checking state
    params[:preparing_visible] == "true" || request.headers["X-Quiz-Preparing"] == "true"
  end

  public

  #-----------------------------------------------------------------------------------------------------------
  # Used for load testing
  #-----------------------------------------------------------------------------------------------------------
  def test_sign_in_random
    sign_in(:user, User.find_by_email("student#{rand(50)}@sttsetia.org"))
    redirect_to "/live_quiz?quiz=16"
  end

end
