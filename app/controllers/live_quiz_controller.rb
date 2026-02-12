# coding: utf-8

class LiveQuizController < ApplicationController
  include ActionController::Live

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

    # Use server-driven state machine for quiz state
    state = calculate_quiz_state(@quiz)

    # Set quiz states based on unified state machine
    # Quiz is only "running" when questions are in progress, not during chat
    @quiz_running = (state[:state] == "running")

    # Quiz is preparing when in "preparing" or "ready" states
    @quiz_preparing = (state[:state] == "preparing" || state[:state] == "ready")

    # Show quiz interface when in preparing, ready, or running states
    @show_quiz_interface = ["preparing", "ready", "running"].include?(state[:state])

    # Get next scheduled quiz time only when quiz hasn't started yet
    # Show next quiz time only during waiting, none, or finished states (not during ready/chat)
    if ["none", "waiting", "finished"].include?(state[:state])
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

  #-----------------------------------------------------------------------------------------------------------
  # Server-Sent Events endpoint for real-time quiz state updates
  #-----------------------------------------------------------------------------------------------------------
  def quiz_events
    # Generate unique connection ID
    connection_id = SecureRandom.uuid
    user_id = current_user&.id || "anonymous-#{request.remote_ip}"
    quiz_id = (params[:id] || params[:quiz_id] || 1).to_i

    # Set SSE headers
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no' # Disable Nginx buffering
    response.headers['Connection'] = 'keep-alive'

    # Initialize connection manager
    connection_manager = SseConnectionManager.instance

    # Variables to track threads
    redis_thread = nil
    heartbeat_thread = nil
    redis_client = nil
    connected = false

    begin
      # Register connection with rate limiting
      connection_manager.register_connection(user_id, quiz_id, connection_id)
      connected = true

      quiz = Quiz.find(quiz_id)

      # Send initial state
      state = calculate_quiz_state(quiz)
      response.stream.write("event: quiz-state\n")
      response.stream.write("data: #{state.to_json}\n\n")

      # Set up Redis subscription for state changes
      redis_thread = Thread.new do
        begin
          redis_client = Redis.new(
            connect_timeout: 5,
            read_timeout: 120,
            write_timeout: 5
          )

          redis_client.subscribe("quiz:#{quiz_id}:state") do |on|
            on.message do |channel, message|
              begin
                data = JSON.parse(message)

                # Send state update to client
                response.stream.write("event: quiz-state\n")
                response.stream.write("data: #{data.to_json}\n\n")

                # If quiz is starting, instruct client to reload
                if data['state'] == 'running' && data['previous_state'] != 'running'
                  reload_data = { action: 'reload', state: 'running', message: 'Quiz is starting' }
                  response.stream.write("event: quiz-state\n")
                  response.stream.write("data: #{reload_data.to_json}\n\n")
                end
              rescue IOError => e
                # Stream closed, exit gracefully
                Rails.logger.info "SSE stream closed for connection #{connection_id}: #{e.message}"
                Thread.exit
              rescue => e
                Rails.logger.error "SSE message error for connection #{connection_id}: #{e.message}"
              end
            end
          end
        rescue => e
          Rails.logger.error "Redis subscription error for connection #{connection_id}: #{e.message}"
        ensure
          redis_client&.close rescue nil
        end
      end

      # Keep connection alive with heartbeat
      heartbeat_thread = Thread.new do
        begin
          loop do
            sleep 30
            break unless connected

            begin
              response.stream.write(":heartbeat\n\n")
              connection_manager.update_heartbeat(connection_id)
            rescue IOError => e
              # Stream closed
              Rails.logger.info "Heartbeat failed for connection #{connection_id}: #{e.message}"
              break
            end
          end
        rescue => e
          Rails.logger.error "Heartbeat thread error for connection #{connection_id}: #{e.message}"
        end
      end

      # Wait for client to disconnect
      sleep

    rescue SseConnectionManager::ConnectionLimitExceeded => e
      Rails.logger.warn "SSE connection rejected for user #{user_id}: #{e.message}"
      response.stream.write("event: error\n")
      response.stream.write("data: {\"error\": \"Connection limit exceeded\", \"code\": \"RATE_LIMIT\"}\n\n")
    rescue SseConnectionManager::ConnectionTerminated => e
      Rails.logger.info "SSE connection terminated for #{connection_id}: #{e.message}"
    rescue ActionController::Live::ClientDisconnected => e
      Rails.logger.info "SSE client disconnected for connection #{connection_id}"
    rescue => e
      Rails.logger.error "SSE error for connection #{connection_id}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
    ensure
      # Mark connection as closed
      connected = false

      # Clean up threads safely
      [redis_thread, heartbeat_thread].each do |thread|
        if thread&.alive?
          thread.kill
          thread.join(1) # Wait up to 1 second for thread to finish
        end
      end

      # Close Redis connection
      redis_client&.close rescue nil

      # Unregister connection
      connection_manager.unregister_connection(connection_id) rescue nil

      # Close response stream
      response.stream.close rescue nil

      Rails.logger.info "SSE cleanup completed for connection #{connection_id}"
    end
  end

  # Configuration for quiz state transitions
  QUIZ_PREPARING_WINDOW_SECONDS = Rails.env.production? ? 5 : 2
  QUIZ_STATE_CACHE_TTL = 2 # seconds

  private

  def calculate_quiz_state(quiz)
    # Use Redis to cache state calculations to prevent race conditions
    cache_key = "quiz_state_cache:#{quiz.id}"
    cached_state = Rails.cache.read(cache_key)

    # If we have a recent cached state, use it
    if cached_state && cached_state[:calculated_at] &&
       cached_state[:calculated_at] > QUIZ_STATE_CACHE_TTL.seconds.ago
      return cached_state.except(:calculated_at)
    end

    # Calculate fresh state with proper locking
    Rails.cache.fetch("quiz_state_lock:#{quiz.id}", expires_in: 1.second, race_condition_ttl: 2.seconds) do
      quiz_session = QuizSession.new(quiz.id)
      current_status = quiz_session.get_quiz_status
      metadata = quiz_session.get_quiz_metadata
      now = Time.current.utc

      # Log for debugging
      Rails.logger.debug "Quiz ##{quiz.id} status: #{current_status.inspect}, metadata: #{metadata.inspect}"

      state = nil

      # Check status first, regardless of quiz type
      if current_status.present? && current_status != "Available"
        # Quiz has an active status
        if current_status.include?("Initializing") || current_status.include?("Chat opening soon")
          # Quiz is initializing
          state = {
            state: "preparing",
            next_transition_at: (now + QUIZ_PREPARING_WINDOW_SECONDS.seconds).iso8601,
            transition_to: "ready",
            should_refresh: false,
            status_details: current_status
          }
        elsif current_status.include?("Chat open. Wait for question")
          # Quiz is ready, user should refresh if they see the preparing overlay
          state = {
            state: "ready",
            should_refresh: user_sees_preparing_overlay?,
            next_transition_at: nil,
            transition_to: "running",
            status_details: current_status
          }
        elsif current_status.match?(/Question \d+ in progress/) || (current_status.include?("In progress") && !current_status.include?("Chat") && !current_status.include?("Initializing"))
          # Quiz running (question in progress)
          state = {
            state: "running",
            should_refresh: false,
            next_transition_at: nil,
            transition_to: "finished",
            status_details: current_status
          }
        elsif current_status == "Finished"
          # Quiz explicitly finished
          state = {
            state: "finished",
            should_refresh: false,
            next_transition_at: nil,
            transition_to: nil,
            status_details: current_status
          }
        end
      end

      # No active status, check schedule
      if state.nil?
        if quiz.id == 1
          # Knowledge quiz uses scheduled times
          next_quiz_time = Quiz.next_knowledge_quiz_time

          if next_quiz_time && next_quiz_time > now
            time_until_start = next_quiz_time - now

            if time_until_start <= QUIZ_PREPARING_WINDOW_SECONDS.seconds
              # Worker about to start
              state = {
                state: "preparing",
                next_transition_at: next_quiz_time.iso8601,
                transition_to: "ready",
                should_refresh: false
              }
            else
              # Waiting for quiz
              state = {
                state: "waiting",
                next_transition_at: (next_quiz_time - QUIZ_PREPARING_WINDOW_SECONDS.seconds).iso8601,
                transition_to: "preparing",
                should_refresh: false
              }
            end
          else
            # No quiz scheduled or quiz finished
            state = {
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

            if time_until_start <= QUIZ_PREPARING_WINDOW_SECONDS.seconds
              # Worker about to start
              state = {
                state: "preparing",
                next_transition_at: quiz.start_time.iso8601,
                transition_to: "ready",
                should_refresh: false
              }
            else
              # Waiting for quiz
              state = {
                state: "waiting",
                next_transition_at: (quiz.start_time - QUIZ_PREPARING_WINDOW_SECONDS.seconds).iso8601,
                transition_to: "preparing",
                should_refresh: false
              }
            end
          else
            # No quiz scheduled or quiz finished
            state = {
              state: current_status == "Finished" ? "finished" : "none",
              should_refresh: false,
              next_transition_at: nil,
              transition_to: nil
            }
          end
        end
      end

      # Cache the calculated state
      Rails.cache.write(cache_key, state.merge(calculated_at: now), expires_in: QUIZ_STATE_CACHE_TTL.seconds)

      state
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
