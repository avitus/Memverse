class ScheduledQuiz

  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: false # Don't retry quiz if something goes wrong

  # Redis lock key for preventing concurrent quiz execution
  LOCK_TIMEOUT = 3600 # 1 hour in seconds

  def perform
    worker_start_time = Time.current.utc
    Sidekiq.logger.info "===> ScheduledQuiz Worker starting at #{worker_start_time}"
    Sidekiq.logger.info "===> Process ID: #{Process.pid}, Thread: #{Thread.current.object_id}"

    begin
      # ========================================================================
      # Try to find quiz starting in next minute, else return false
      # ========================================================================
      Sidekiq.logger.info "===> Searching for scheduled quizzes..."
      quiz = find_scheduled_quiz
      
      if quiz.nil?
        Sidekiq.logger.info "===> No quiz found. Worker exiting."
        return
      else
        Sidekiq.logger.info "===> Found quiz ##{quiz.id}: '#{quiz.name}'"
        Sidekiq.logger.info "===> Quiz start_time: #{quiz.start_time} (#{quiz.start_time.strftime('%Y-%m-%d %H:%M:%S UTC')})"
        Sidekiq.logger.info "===> Current time: #{Time.current.utc} (#{Time.current.utc.strftime('%Y-%m-%d %H:%M:%S UTC')})"
        Sidekiq.logger.info "===> Time until start: #{(quiz.start_time - Time.current.utc).round(2)} seconds"
      end
      
      # ========================================================================
      # Verify that quiz has not been started by another worker
      # ========================================================================
      channel = "quiz-#{quiz.id}"
      
      # Initialize QuizSession service
      @quiz_session = QuizSession.new(quiz.id)
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Initialized QuizSession service"
      
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Attempting to acquire quiz lock..."
      unless acquire_quiz_lock(quiz.id)
        Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Already running (lock held by another worker), aborting this execution"
        Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Lock status: #{@quiz_session.quiz_locked?}"
        return
      end
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Successfully acquired quiz lock"

      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Checking if quiz is already in progress..."
      if quiz_in_progress?(channel)
        current_status = @quiz_session.get_quiz_status
        Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Already in progress (status: '#{current_status}'), aborting"
        return
      end

      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Grabbed by ScheduledQuiz worker (PID: #{Process.pid})"
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Using channel '#{channel}' for PubNub messaging"

      # Initialize quiz
      initialize_quiz(quiz, channel)
      
    rescue => e
      handle_quiz_error("quiz initialization", e, quiz&.id)
      return
    ensure
      release_quiz_lock(quiz&.id) if quiz
    end

    begin
      # Execute the main quiz logic
      execute_quiz(quiz, channel, worker_start_time)
      
    rescue => e
      handle_quiz_error("main quiz execution", e, quiz.id, channel)
      mark_quiz_failed(channel)
    ensure
      cleanup_quiz_resources(quiz&.id, channel)
    end
  end

  private

  # ========================================================================
  # Quiz finding and validation
  # ========================================================================
  
  def find_scheduled_quiz
    Sidekiq.logger.info "===> Looking for a scheduled quiz"

    # Use UTC for all time comparisons
    current_time = Time.current.utc
    time_window_start = current_time
    time_window_end = current_time + 1.minute
    
    Sidekiq.logger.info "===> Search window: #{time_window_start.strftime('%Y-%m-%d %H:%M:%S')} to #{time_window_end.strftime('%Y-%m-%d %H:%M:%S')} UTC"
    
    # First, let's see what quizzes exist
    all_quizzes = Quiz.where.not(id: 1).order(start_time: :asc).limit(5)
    Sidekiq.logger.info "===> Next 5 quizzes (excluding ID 1):"
    all_quizzes.each do |q|
      time_diff = (q.start_time - current_time).round(2)
      Sidekiq.logger.info "===>   Quiz ##{q.id} '#{q.name}' starts at #{q.start_time.strftime('%Y-%m-%d %H:%M:%S')} UTC (in #{time_diff}s)"
    end
    
    quiz = Quiz.where("start_time > ? AND start_time < ?", time_window_start, time_window_end).first

    if quiz.nil?
      Sidekiq.logger.debug "===> No scheduled quiz found for current time window"
      return nil
    end

    Sidekiq.logger.info "===> Found quiz ##{quiz.id} '#{quiz.name}' within time window"

    if quiz.quiz_questions.count == 0
      Sidekiq.logger.warn "===> Quiz ##{quiz.id} has no questions, skipping"
      return nil
    end

    if quiz.id == 1
      Sidekiq.logger.debug "===> Quiz ##{quiz.id} is the Wed/Sat quiz, handled by KnowledgeQuiz worker"
      return nil
    end

    Sidekiq.logger.info "===> Found scheduled quiz ##{quiz.id} with #{quiz.quiz_questions.count} questions"
    quiz
  end

  # ========================================================================
  # Lock management and concurrency control
  # ========================================================================
  
  def quiz_lock_key(quiz_id)
    "scheduled_quiz_lock_#{quiz_id}"
  end
  
  def acquire_quiz_lock(quiz_id)
    @quiz_session.lock_quiz(LOCK_TIMEOUT)
  end
  
  def release_quiz_lock(quiz_id)
    return unless quiz_id
    @quiz_session.unlock_quiz
  end
  
  def quiz_in_progress?(channel)
    @quiz_session.quiz_in_progress?
  end

  # ========================================================================
  # Quiz initialization
  # ========================================================================
  
  def initialize_quiz(quiz, channel)
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Entering initialize_quiz method"
    
    # Save status of quiz in redis with timestamp
    initial_status = "In progress. Chat opening soon."
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Setting initial status: '#{initial_status}'"
    @quiz_session.set_quiz_status(initial_status, {
      start_time: Time.current.utc.iso8601,
      quiz_id: quiz.id
    })

    # Wait until the quiz start time (use UTC comparison)
    current_time = Time.current.utc
    sleep_time = quiz.start_time - current_time
    
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Current time: #{current_time.strftime('%Y-%m-%d %H:%M:%S UTC')}"
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Quiz start time: #{quiz.start_time.strftime('%Y-%m-%d %H:%M:%S UTC')}"
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Sleep time calculated: #{sleep_time.round(2)} seconds"
    
    if sleep_time && sleep_time > 0
      Sidekiq.logger.info("===> Quiz ##{quiz.id} : Sleeping #{sleep_time.round(2)} seconds till chat opens")
      sleep sleep_time
      new_status = "In progress. Chat open. Wait for question."
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Woke up! Setting status: '#{new_status}'"
      @quiz_session.set_quiz_status(new_status)
    else
      Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Sleep time is negative or zero (#{sleep_time}), proceeding immediately"
      @quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
    end
    
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Quiz initialization complete"
  end

  # ========================================================================
  # Main quiz execution
  # ========================================================================
  
  def execute_quiz(quiz, channel, worker_start_time)
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Starting execute_quiz method"
    quiz_actual_start = Time.current.utc
    
    # ========================================================================
    # Announce quiz
    # ========================================================================
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 1/7 - Announcing quiz"
    announce_quiz(quiz)

    # ========================================================================
    # Setup quiz, clear old scores
    # ========================================================================
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 2/7 - Setting up quiz environment"
    setup_quiz_environment(quiz, channel)

    # ========================================================================
    # Open quiz chat channel 5 minutes prior to start
    # ========================================================================
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 3/7 - Opening chat channel"
    open_chat_channel(quiz, channel)

    # ========================================================================
    # Main question loop
    # ========================================================================
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 4/7 - Running quiz questions"
    run_quiz_questions(quiz, channel)

    # ========================================================================
    # Finalize quiz and record final scoreboard
    # ========================================================================
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 5/7 - Finalizing quiz"
    finalize_quiz(quiz, channel)
    
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 6/7 - Recording final scoreboard"
    record_final_scoreboard(quiz, channel)

    # ========================================================================
    # Close chat after ten minutes
    # ========================================================================
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Step 7/7 - Closing quiz chat"
    close_quiz_chat(quiz, channel)

    quiz_end_time = Time.current.utc
    quiz_duration = quiz_end_time - quiz_actual_start
    
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : COMPLETED! Total duration: #{quiz_duration.round(2)} seconds"
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Recording success metrics"
    record_quiz_success(quiz, channel, quiz_actual_start, quiz_end_time)
  end

  # ========================================================================
  # Quiz announcement
  # ========================================================================
  
  def announce_quiz(quiz)
    with_retry("quiz announcement", quiz.id) do
      broadcast = "#{quiz.name} is starting. <a href=\"live_quiz/#{quiz.id}\">Join now!</a>"
      Tweet.create!(news: broadcast, user_id: 1, importance: 2)
    end
  end

  # ========================================================================
  # Quiz environment setup
  # ========================================================================
  
  def setup_quiz_environment(quiz, channel)
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Opening quiz room at #{Time.current.utc}"

    with_retry("clearing Redis data", quiz.id) do
      # Clear participant and question scores using QuizSession service
      @quiz_session.cleanup_quiz_data
      
      # Also clean up legacy format keys for backward compatibility
      @quiz_session.cleanup_legacy_data
    end

    # Save status of quiz in redis
    @quiz_session.set_quiz_status("In progress. Wait for question.")
  end

  # ========================================================================
  # Chat management
  # ========================================================================
  
  def open_chat_channel(quiz, channel)
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Opening chat at #{Time.current.utc}"

    with_retry("opening chat channel", quiz.id) do
      status = nil
      chat_key = "chat-#{channel}"
      
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Checking if chat channel exists in Redis (key: #{chat_key})"
      if $redis.exists(chat_key)
        status = $redis.hmget(chat_key, "status").first
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Existing chat status: '#{status}'"
      else
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : No existing chat channel found"
      end

      unless status&.== "Open"
        new_status = "Open"
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Setting chat status to '#{new_status}'"
        $redis.hset(chat_key, "status", new_status)
        
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Publishing chat_status message via PubNub"
        publish_with_retry(channel, {
          meta: "chat_status",
          status: new_status
        }, quiz.id)
      else
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Chat already open, skipping status update"
      end
    end

    # 5 minutes for chatting (shorter in non-production for testing)
    chat_duration = Rails.env.production? ? 300 : 30
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Chat period started - waiting #{chat_duration} seconds"
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Participants can now join at /live_quiz/#{quiz.id}"
    sleep(chat_duration)
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Chat period ended, proceeding to questions"
  end

  # ========================================================================
  # Quiz question execution
  # ========================================================================
  
  def run_quiz_questions(quiz, channel)
    Sidekiq.logger.info("===> Quiz ##{quiz.id} : Starting quiz questions at #{Time.current.utc}")

    quiz_questions = quiz.quiz_questions.order("question_no ASC")
    Sidekiq.logger.info("===> Quiz ##{quiz.id} : Loading #{quiz_questions.count} questions")
    
    # Log all questions for debugging
    quiz_questions.each_with_index do |q, idx|
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Question #{idx+1}: Type=#{q.question_type}, ID=#{q.id}, Passage=#{q.passage}"
    end

    quiz_questions.each_with_index do |question, idx|
      with_retry("question #{question.question_no}", quiz.id) do
        passages = question.passage_translations
        ref = question.passage
        num = question.question_no

        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Processing Question ##{num} (#{idx+1} of #{quiz_questions.count}) [Type: #{question.question_type}]"

        # Store question metadata in Redis
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Updating question stats in Redis"
        @quiz_session.update_question_stats(num, question.id)

        case question.question_type
        when "recitation"
          Sidekiq.logger.info "===> Quiz ##{quiz.id} : Question ##{num} - Recitation question for passage: #{ref}"
          handle_recitation_question(question, num, ref, passages, channel, quiz.id)
        when "reference"
          Sidekiq.logger.info "===> Quiz ##{quiz.id} : Question ##{num} - Reference question for passage: #{ref}"
          handle_reference_question(question, num, ref, passages, channel, quiz.id)
        when "mcq"
          Sidekiq.logger.info "===> Quiz ##{quiz.id} : Question ##{num} - Multiple choice question"
          handle_mcq_question(question, num, channel, quiz.id)
        else
          Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Question ##{num} - Unknown question type: #{question.question_type}"
          sleep(20)
        end

        # Publish updated scoreboard after each question
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Publishing scoreboard after question ##{num}"
        publish_scoreboard(channel, quiz.id)
        
        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Completed question ##{num}"
      end
    end
    
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : All questions completed"
  end
  
  def handle_recitation_question(question, num, ref, passages, channel, quiz_id)
    # Calculate time allocation: 24 WPM typing speed with 15 seconds to think
    time_alloc = (passages.first.last.split(" ").length * 2.5 + 15.0).to_i

    publish_with_retry(channel, {
      meta: "question",
      q_num: num,
      q_id: question.id,
      q_type: "recitation",
      q_ref: ref,
      q_passages: passages,
      time_alloc: time_alloc
    }, quiz_id)
    
    sleep(time_alloc + 1)
  end
  
  def handle_reference_question(question, num, ref, passages, channel, quiz_id)
    publish_with_retry(channel, {
      meta: "question",
      q_num: num,
      q_id: question.id,
      q_type: "reference",
      q_ref: ref,
      q_passages: passages,
      time_alloc: 25
    }, quiz_id)
    
    sleep(26)
  end
  
  def handle_mcq_question(question, num, channel, quiz_id)
    publish_with_retry(channel, {
      meta: "question",
      q_num: num,
      q_id: question.id,
      q_type: "mcq",
      mc_question: question.mc_question,
      mc_option_a: question.mc_option_a,
      mc_option_b: question.mc_option_b,
      mc_option_c: question.mc_option_c,
      mc_option_d: question.mc_option_d,
      mc_answer: question.mc_answer,
      time_alloc: 30
    }, quiz_id)
    
    sleep(31)
  end
  
  def publish_scoreboard(channel, quiz_id)
    with_retry("publishing scoreboard", quiz_id) do
      scoreboard = @quiz_session.get_scoreboard

      publish_with_retry(channel, {
        meta: "scoreboard",
        scoreboard: scoreboard
      }, quiz_id)
    end
  end

  # ========================================================================
  # Quiz finalization
  # ========================================================================
  
  def finalize_quiz(quiz, channel)
    with_retry("finalizing quiz", quiz.id) do
      @quiz_session.set_quiz_status("Finished", {
        end_time: Time.current.utc.iso8601
      })
      Sidekiq.logger.info("===> Quiz ##{quiz.id} : Finished quiz at #{Time.current.utc}")
    end
  end
  
  def record_final_scoreboard(quiz, channel)
    with_retry("recording final scoreboard", quiz.id) do
      final_scoreboard = @quiz_session.get_scoreboard

      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Final Quiz Scores"
      Sidekiq.logger.info "==================="
      final_scoreboard.each do |usr|
        Sidekiq.logger.info "[#{usr['score']}] - #{usr['name']}"
      end

      # Announce winner if there are participants
      unless final_scoreboard.empty?
        gold_ribbon_name = final_scoreboard[0]['name']
        gold_ribbon_id = final_scoreboard[0]['id']
        broadcast = "#{gold_ribbon_name} won #{quiz.name}"
        Tweet.create!(news: broadcast, user_id: gold_ribbon_id, importance: 2)
      end
    end
  end
  
  def close_quiz_chat(quiz, channel)
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Quiz over. Sleeping for 10 minutes, then shutting down chat."
    
    # Wait before closing chat (shorter in non-production for testing)
    wait_duration = Rails.env.production? ? 600 : 30
    sleep(wait_duration)

    with_retry("closing chat", quiz.id) do
      new_status = "Closed"
      $redis.hset("chat-#{channel}", "status", new_status)
      
      publish_with_retry(channel, {
        meta: "chat_status",
        status: new_status
      }, quiz.id)
    end

    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Chat closed and sidekiq job finished."
  end

  # ========================================================================
  # Error handling and retry logic
  # ========================================================================
  
  def with_retry(operation_name, quiz_id, max_retries: 3, &block)
    retries = 0
    begin
      block.call
    rescue => e
      retries += 1
      if retries <= max_retries
        wait_time = retries * 2 # Exponential backoff: 2, 4, 6 seconds
        Sidekiq.logger.warn "Quiz ##{quiz_id} #{operation_name} failed (attempt #{retries}/#{max_retries}): #{e.message}. Retrying in #{wait_time} seconds..."
        sleep(wait_time)
        retry
      else
        Sidekiq.logger.error "Quiz ##{quiz_id} #{operation_name} failed after #{max_retries} attempts: #{e.message}"
        raise e
      end
    end
  end
  
  def publish_with_retry(channel, message, quiz_id, max_retries: 3)
    retries = 0
    Sidekiq.logger.info "===> Quiz ##{quiz_id} : Publishing PubNub message to channel '#{channel}'"
    Sidekiq.logger.debug "===> Quiz ##{quiz_id} : Message content: #{message.inspect}"
    
    begin
      result = PN.publish(
        channel: channel,
        message: message,
        http_sync: true,
        callback: PN_CALLBACK
      )
      
      if result
        Sidekiq.logger.info "===> Quiz ##{quiz_id} : PubNub publish successful - timetoken: #{result.timetoken}"
      else
        Sidekiq.logger.warn "===> Quiz ##{quiz_id} : PubNub publish returned nil result"
      end
      
      result
    rescue => e
      retries += 1
      if retries <= max_retries
        wait_time = retries * 2
        Sidekiq.logger.warn "Quiz ##{quiz_id} PubNub publish failed (attempt #{retries}/#{max_retries}): #{e.message}. Retrying in #{wait_time} seconds..."
        Sidekiq.logger.warn "Quiz ##{quiz_id} Error class: #{e.class}, Backtrace: #{e.backtrace.first(3).join(' | ')}"
        sleep(wait_time)
        retry
      else
        Sidekiq.logger.error "Quiz ##{quiz_id} PubNub publish failed after #{max_retries} attempts: #{e.message}"
        raise e
      end
    end
  end
  
  def handle_quiz_error(context, error, quiz_id = nil, channel = nil)
    error_message = "ScheduledQuiz error during #{context}"
    error_message += " for quiz ##{quiz_id}" if quiz_id
    error_message += ": #{error.class} - #{error.message}"
    
    Sidekiq.logger.error error_message
    Sidekiq.logger.error error.backtrace.join("
")
    
    # Try to notify participants about the error
    if channel
      begin
        publish_with_retry(channel, {
          meta: "error",
          message: "Quiz experienced technical difficulties and has been stopped."
        }, quiz_id, max_retries: 1)
      rescue => notification_error
        Sidekiq.logger.error "Failed to notify participants of error: #{notification_error.message}"
      end
    end
  end
  
  def mark_quiz_failed(channel)
    @quiz_session.set_quiz_status("Failed", {
      error_time: Time.current.utc.iso8601
    })
  end

  # ========================================================================
  # Health monitoring and cleanup
  # ========================================================================
  
  def record_quiz_success(quiz, channel, start_time, end_time)
    @quiz_session.set_quiz_status("Available", {
      last_success: end_time.iso8601,
      duration_seconds: (end_time - start_time).round(2),
      success_count: (@quiz_session.get_quiz_metadata["success_count"].to_i + 1)
    })
  end
  
  def cleanup_quiz_resources(quiz_id, channel)
    # Mark quiz as available again
    @quiz_session.set_quiz_status("Available") if @quiz_session
    
    # Clean up any stale locks
    @quiz_session.unlock_quiz if @quiz_session
    
    Sidekiq.logger.info "Quiz ##{quiz_id} resources cleaned up"
  end

end
