class ScheduledQuiz

  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: false # Don't retry quiz if something goes wrong

  # Redis lock key for preventing concurrent quiz execution
  LOCK_TIMEOUT = 3600 # 1 hour in seconds

  def perform
    worker_start_time = Time.current.utc
    Sidekiq.logger.info "===> ScheduledQuiz Worker starting at #{worker_start_time}"

    begin
      # ========================================================================
      # Try to find quiz starting in next minute, else return false
      # ========================================================================
      quiz = find_scheduled_quiz
      return unless quiz
      
      # ========================================================================
      # Verify that quiz has not been started by another worker
      # ========================================================================
      channel = "quiz-#{quiz.id}"
      
      # Initialize QuizSession service
      @quiz_session = QuizSession.new(quiz.id)
      
      unless acquire_quiz_lock(quiz.id)
        Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Already running, aborting this execution"
        return
      end

      if quiz_in_progress?(channel)
        Sidekiq.logger.warn "===> Quiz ##{quiz.id} : Already in progress, aborting"
        return
      end

      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Grabbed by ScheduledQuiz worker"
      Sidekiq.logger.info "===> Quiz ##{quiz.id} : Using channel #{channel}"

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
    quiz = Quiz.where("start_time > ? AND start_time < ?", current_time, current_time + 1.minute).first

    if quiz.nil?
      Sidekiq.logger.debug "===> No scheduled quiz found for current time window"
      return nil
    end

    if quiz.quiz_questions.count == 0
      Sidekiq.logger.warn "===> Quiz ##{quiz.id} has no questions, skipping"
      return nil
    end

    if quiz.id == 1
      Sidekiq.logger.debug "===> Quiz ##{quiz.id} is the Wed/Sat quiz, handled by different worker"
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
    # Save status of quiz in redis with timestamp
    @quiz_session.set_quiz_status("In progress. Chat opening soon.", {
      start_time: Time.current.utc.iso8601,
      quiz_id: quiz.id
    })

    # Wait until the quiz start time (use UTC comparison)
    if (sleep_time = quiz.start_time - Time.current.utc) && sleep_time > 0
      Sidekiq.logger.info("===> Quiz ##{quiz.id} : Sleeping #{sleep_time.round(2)} seconds till chat opens")
      sleep sleep_time
      @quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
    end
  end

  # ========================================================================
  # Main quiz execution
  # ========================================================================
  
  def execute_quiz(quiz, channel, worker_start_time)
    quiz_actual_start = Time.current.utc
    
    # ========================================================================
    # Announce quiz
    # ========================================================================
    announce_quiz(quiz)

    # ========================================================================
    # Setup quiz, clear old scores
    # ========================================================================
    setup_quiz_environment(quiz, channel)

    # ========================================================================
    # Open quiz chat channel 5 minutes prior to start
    # ========================================================================
    open_chat_channel(quiz, channel)

    # ========================================================================
    # Main question loop
    # ========================================================================
    run_quiz_questions(quiz, channel)

    # ========================================================================
    # Finalize quiz and record final scoreboard
    # ========================================================================
    finalize_quiz(quiz, channel)
    record_final_scoreboard(quiz, channel)

    # ========================================================================
    # Close chat after ten minutes
    # ========================================================================
    close_quiz_chat(quiz, channel)

    quiz_end_time = Time.current.utc
    quiz_duration = quiz_end_time - quiz_actual_start
    
    Sidekiq.logger.info "===> Quiz ##{quiz.id} completed successfully in #{quiz_duration.round(2)} seconds"
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
      if $redis.exists("chat-#{channel}")
        status = $redis.hmget("chat-#{channel}", "status").first
      end

      unless status&.== "Open"
        new_status = "Open"
        $redis.hset("chat-#{channel}", "status", new_status)
        
        publish_with_retry(channel, {
          meta: "chat_status",
          status: new_status
        }, quiz.id)
      end
    end

    # 5 minutes for chatting (shorter in non-production for testing)
    chat_duration = Rails.env.production? ? 300 : 30
    Sidekiq.logger.info "===> Quiz ##{quiz.id} : Waiting #{chat_duration} seconds for chat period"
    sleep(chat_duration)
  end

  # ========================================================================
  # Quiz question execution
  # ========================================================================
  
  def run_quiz_questions(quiz, channel)
    Sidekiq.logger.info("===> Quiz ##{quiz.id} : Starting quiz at #{Time.current.utc}")

    quiz_questions = quiz.quiz_questions.order("question_no ASC")
    Sidekiq.logger.info("===> Quiz ##{quiz.id} : has #{quiz_questions.count} questions.")

    quiz_questions.each do |question|
      with_retry("question #{question.question_no}", quiz.id) do
        passages = question.passage_translations
        ref = question.passage
        num = question.question_no

        Sidekiq.logger.info "===> Quiz ##{quiz.id} : Question ##{num} [#{question.question_type}]"

        # Store question metadata in Redis
        @quiz_session.update_question_stats(num, question.id)

        case question.question_type
        when "recitation"
          handle_recitation_question(question, num, ref, passages, channel, quiz.id)
        when "reference"
          handle_reference_question(question, num, ref, passages, channel, quiz.id)
        when "mcq"
          handle_mcq_question(question, num, channel, quiz.id)
        else
          Sidekiq.logger.warn "Unknown question type: #{question.question_type}"
          sleep(20)
        end

        # Publish updated scoreboard after each question
        publish_scoreboard(channel, quiz.id)
      end
    end
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
    begin
      PN.publish(
        channel: channel,
        message: message,
        http_sync: true,
        callback: PN_CALLBACK
      )
    rescue => e
      retries += 1
      if retries <= max_retries
        wait_time = retries * 2
        Sidekiq.logger.warn "Quiz ##{quiz_id} PubNub publish failed (attempt #{retries}/#{max_retries}): #{e.message}. Retrying in #{wait_time} seconds..."
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
