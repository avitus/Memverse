class KnowledgeQuiz

  include Sidekiq::Worker
  include IceCube
  include PushNotification

  sidekiq_options queue: :critical, retry: false # Don't retry quiz if something goes wrong

  # Redis lock key for preventing concurrent quiz execution
  QUIZ_LOCK_KEY = "knowledge_quiz_lock".freeze
  QUIZ_STATUS_KEY = "quiz-bible-knowledge".freeze
  LOCK_TIMEOUT = 3600 # 1 hour in seconds
  
  # Add a unique execution key to prevent duplicate runs within the same time window
  EXECUTION_WINDOW_KEY = "knowledge_quiz_execution_window".freeze
  EXECUTION_WINDOW = 300 # 5 minutes - prevent re-execution within this window

  def perform
    quiz_start_time = Time.current.utc
    quiz_id = 1 # General knowledge quiz always has ID=1
    channel = "quiz-#{quiz_id}"
    
    Sidekiq.logger.info "===> Knowledge Quiz Worker starting at #{quiz_start_time}"
    Sidekiq.logger.info "===> Process ID: #{Process.pid}, Thread: #{Thread.current.object_id}"
    
    # Initialize QuizSession service
    @quiz_session = QuizSession.new(quiz_id)
    
    begin
      # ========================================================================
      # Enhanced idempotency check - prevent duplicate quiz execution
      # ========================================================================
      
      # First check if quiz was recently executed (within execution window)
      if quiz_recently_executed?
        Sidekiq.logger.warn "===> Knowledge quiz was recently executed within the last #{EXECUTION_WINDOW} seconds, aborting"
        return
      end
      
      # Try to acquire execution window lock - this prevents any other process from running quiz
      unless acquire_execution_window_lock
        Sidekiq.logger.warn "===> Another process is already running the knowledge quiz, aborting"
        return
      end
      
      # Now acquire the regular quiz lock
      unless acquire_quiz_lock
        Sidekiq.logger.warn "===> Knowledge quiz already running (regular lock held), aborting this execution"
        return
      end

      # Check if quiz is already in progress (belt and suspenders)
      if quiz_in_progress?
        Sidekiq.logger.warn "===> Knowledge quiz already in progress, aborting"
        return
      end

      # Mark quiz as starting
      mark_quiz_starting
      
      # ========================================================================
      # Announce quiz
      # ========================================================================
      announce_quiz_start
      
      # ========================================================================
      # Calculate start time for next quiz (using UTC)
      # ========================================================================
      next_quiz_time = calculate_next_quiz_time
      
    rescue => e
      handle_quiz_error("quiz initialization", e)
      return
    ensure
      # Always release the lock if we acquired it
      release_quiz_lock
    end

    begin
      # ========================================================================
      # Setup quiz, clear old scores
      # ========================================================================
      setup_quiz_environment(quiz_start_time)
      
      # Select quiz and set up PubNub channel
      quiz = find_quiz
      
      # ========================================================================
      # Open quiz chat channel 5 minutes prior to start
      # ========================================================================
      open_chat_channel(channel)
      
      # ========================================================================
      # Main question loop
      # ========================================================================
      run_quiz_questions(quiz, channel)
      
      # ========================================================================
      # Update quiz status, set start time for next quiz
      # ========================================================================
      finalize_quiz(quiz, next_quiz_time, channel)
      
      # ========================================================================
      # Update difficulty for all questions and record final scoreboard
      # ========================================================================
      update_question_difficulty_and_scoreboard
      
      # ========================================================================
      # Close chat after ten minutes
      # ========================================================================
      close_quiz_chat(channel)
      
      quiz_end_time = Time.current.utc
      quiz_duration = quiz_end_time - quiz_start_time
      
      Sidekiq.logger.info "===> Knowledge Quiz completed successfully in #{quiz_duration.round(2)} seconds"
      record_quiz_success(quiz_start_time, quiz_end_time)
      
    rescue => e
      handle_quiz_error("main quiz execution", e, channel)
      mark_quiz_failed
    ensure
      # Always clean up, regardless of success or failure
      cleanup_quiz_resources
    end
  end

  private

  # ========================================================================
  # Enhanced idempotency and lock management
  # ========================================================================
  
  def quiz_recently_executed?
    # Check if quiz was executed within the execution window
    last_execution = $redis.get(EXECUTION_WINDOW_KEY)
    return false unless last_execution
    
    last_execution_time = Time.parse(last_execution)
    time_since_execution = Time.current.utc - last_execution_time
    
    Sidekiq.logger.info "===> Last quiz execution was #{time_since_execution.round(2)} seconds ago"
    time_since_execution < EXECUTION_WINDOW
  rescue => e
    Sidekiq.logger.error "Error checking recent execution: #{e.message}"
    false
  end
  
  def acquire_execution_window_lock
    # Use Redis SET with NX (only set if not exists) and EX (expiry)
    # This is an atomic operation that prevents race conditions
    lock_key = "#{QUIZ_LOCK_KEY}_execution"
    lock_value = "#{Process.pid}:#{Thread.current.object_id}:#{Time.current.utc.iso8601}"
    
    # Try to acquire lock with a short expiry (5 minutes)
    result = $redis.set(lock_key, lock_value, nx: true, ex: EXECUTION_WINDOW)
    
    if result
      # Also set the execution window timestamp
      $redis.set(EXECUTION_WINDOW_KEY, Time.current.utc.iso8601, ex: EXECUTION_WINDOW)
      Sidekiq.logger.info "===> Successfully acquired execution window lock"
      true
    else
      Sidekiq.logger.warn "===> Failed to acquire execution window lock - another process has it"
      false
    end
  end
  
  def acquire_quiz_lock
    @quiz_session.lock_quiz(LOCK_TIMEOUT)
  end
  
  def release_quiz_lock
    @quiz_session.unlock_quiz
  end
  
  def quiz_in_progress?
    @quiz_session.quiz_in_progress?
  end
  
  def mark_quiz_starting
    @quiz_session.set_quiz_status("In progress. Initializing...", {
      start_time: Time.current.utc.iso8601
    })
  end
  
  def mark_quiz_failed
    @quiz_session.set_quiz_status("Failed", {
      error_time: Time.current.utc.iso8601
    })
  end

  # ========================================================================
  # Quiz announcement and scheduling
  # ========================================================================
  
  def announce_quiz_start
    with_retry("quiz announcement") do
      # Log the announcement to help debug duplicates
      Sidekiq.logger.info "===> Creating quiz start announcement tweet (Process: #{Process.pid})"
      
      broadcast = "The Bible knowledge quiz is starting. <a href=\"live_quiz\">Join now!</a>"
      tweet = Tweet.create!(news: broadcast, user_id: 1, importance: 2)
      
      Sidekiq.logger.info "===> Created tweet ID: #{tweet.id} at #{tweet.created_at}"
      
      ios_quiz_alert("The Bible trivia quiz is starting now.")
    end
  end
  
  def calculate_next_quiz_time
    # Use UTC timezone for all scheduling calculations
    schedule = IceCube::Schedule.new(Time.current.utc)
    # Wednesday 9 AM UTC
    schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:wednesday).hour_of_day(9).minute_of_hour(0).second_of_minute(0))
    # Saturday 3 PM UTC  
    schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:saturday).hour_of_day(15).minute_of_hour(0).second_of_minute(0))
    schedule.next_occurrence
  end

  # ========================================================================
  # Quiz setup and initialization
  # ========================================================================
  
  def setup_quiz_environment(start_time)
    Sidekiq.logger.info "===> Opening quiz room at #{start_time}"

    with_retry("clearing Redis data") do
      # Clear participant and question scores using QuizSession service
      @quiz_session.cleanup_quiz_data
      
      # Also clean up legacy format keys for backward compatibility
      @quiz_session.cleanup_legacy_data
    end

    # Save status of quiz in redis
    @quiz_session.set_quiz_status("In progress. Wait for question.")
  end
  
  def find_quiz
    Quiz.find(1)
  rescue ActiveRecord::RecordNotFound => e
    raise "Knowledge quiz (ID=1) not found in database: #{e.message}"
  end

  # ========================================================================
  # Chat management
  # ========================================================================
  
  def open_chat_channel(channel)
    Sidekiq.logger.info "===> Opening chat at #{Time.current.utc}"
    
    with_retry("opening chat channel") do
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
        })
      end
    end

    # 5 minutes for chatting (shorter in non-production for testing)
    chat_duration = Rails.env.production? ? 300 : 30
    Sidekiq.logger.info "===> Waiting #{chat_duration} seconds for chat period"
    sleep(chat_duration)
  end

  # ========================================================================
  # Quiz question execution
  # ========================================================================
  
  def run_quiz_questions(quiz, channel)
    question_count = Rails.env.production? ? 25 : 3
    q_num_array = Array(1..question_count)

    Sidekiq.logger.info "===> Starting quiz at #{Time.current.utc} with #{question_count} questions"

    q_num_array.each do |q_num|
      with_retry("question #{q_num}") do
        Sidekiq.logger.info "===> Question: #{q_num}"

        # Pick a question at random
        question = QuizQuestion.mcq.approved.order(:last_asked).first
        
        if question.nil?
          Sidekiq.logger.error "===> No approved MCQ questions found for question #{q_num}"
          next
        end

        # Store question metadata in Redis
        @quiz_session.update_question_stats(q_num, question.id)

        # Update question to show that it was asked today (use UTC)
        question.update!(last_asked: Date.current)

        # Publish question
        publish_with_retry(channel, {
          meta: "question",
          q_id: question.id,
          q_num: q_num,
          q_type: "mcq",
          mc_question: question.mc_question,
          mc_option_a: question.mc_option_a,
          mc_option_b: question.mc_option_b,
          mc_option_c: question.mc_option_c,
          mc_option_d: question.mc_option_d,
          mc_answer: question.mc_answer,
          time_alloc: question.time_allocation
        })

        # Time to answer question
        sleep(question.time_allocation)

        # Update and publish scoreboard
        publish_scoreboard(channel)
      end
    end
  end
  
  def publish_scoreboard(channel)
    Sidekiq.logger.info "===> Updating scoreboard"
    
    with_retry("publishing scoreboard") do
      scoreboard = @quiz_session.get_scoreboard

      publish_with_retry(channel, {
        meta: "scoreboard",
        scoreboard: scoreboard
      })
    end
  end

  # ========================================================================
  # Quiz finalization
  # ========================================================================
  
  def finalize_quiz(quiz, next_quiz_time, channel)
    with_retry("finalizing quiz") do
      @quiz_session.set_quiz_status("Finished", {
        end_time: Time.current.utc.iso8601
      })
      
      Sidekiq.logger.info "===> Finished quiz at #{Time.current.utc}"

      quiz.update!(start_time: next_quiz_time)
      Sidekiq.logger.info "Next knowledge quiz will start at #{next_quiz_time}"
    end
  end
  
  def update_question_difficulty_and_scoreboard
    with_retry("updating question difficulty") do
      quiz_table = @quiz_session.get_question_stats

      Sidekiq.logger.info '----------------------------------------------------------------------------------------'
      Sidekiq.logger.info '#  |  ID  |  Answers Submitted  |  Total Score'
      Sidekiq.logger.info '----------------------------------------------------------------------------------------'
      
      quiz_table.each_with_index do |qq, index|
        q_id = qq['qq_id'].to_i
        q_count = qq['answered'].to_i
        q_total = qq['total_score'].to_i
        q_perc_correct = q_count > 0 ? (q_total.to_f / q_count * 10) : 0

        Sidekiq.logger.info "#{index}      #{qq['qq_id']}         #{qq['answered']}                  #{qq['total_score']}"

        # Update quiz question difficulty in database
        begin
          question = QuizQuestion.find(q_id)
          question.update_difficulty(q_count, q_perc_correct)
        rescue ActiveRecord::RecordNotFound => e
          Sidekiq.logger.error "Question #{q_id} not found: #{e.message}"
        end
      end
    end

    # Record final scoreboard and announce winner
    record_final_scoreboard
  end
  
  def record_final_scoreboard
    with_retry("recording final scoreboard") do
      final_scoreboard = @quiz_session.get_scoreboard

      Sidekiq.logger.info "Final Quiz Scores"
      Sidekiq.logger.info "==================="
      final_scoreboard.each do |usr|
        Sidekiq.logger.info "[#{usr['score']}] - #{usr['name']}"
      end

      # Announce winner if there are participants
      unless final_scoreboard.empty?
        gold_ribbon_name = final_scoreboard[0]['name']
        gold_ribbon_id = final_scoreboard[0]['id']
        
        # Log winner announcement to help debug duplicates
        Sidekiq.logger.info "===> Creating winner announcement tweet for #{gold_ribbon_name} (Process: #{Process.pid})"
        
        broadcast = "#{gold_ribbon_name} won the Bible knowledge quiz"
        tweet = Tweet.create!(news: broadcast, user_id: gold_ribbon_id, importance: 2)
        
        Sidekiq.logger.info "===> Created winner tweet ID: #{tweet.id} at #{tweet.created_at}"
      end
    end
  end
  
  def close_quiz_chat(channel)
    Sidekiq.logger.info "Quiz now over. Sleeping for 10 minutes, then shutting down chat."
    
    # Wait before closing chat (shorter in non-production for testing)
    wait_duration = Rails.env.production? ? 600 : 30
    sleep(wait_duration)

    with_retry("closing chat") do
      new_status = "Closed"
      $redis.hset("chat-#{channel}", "status", new_status)
      
      publish_with_retry(channel, {
        meta: "chat_status",
        status: new_status
      })
    end

    Sidekiq.logger.info "Chat closed and sidekiq job finished."
  end

  # ========================================================================
  # Error handling and retry logic
  # ========================================================================
  
  def with_retry(operation_name, max_retries: 3, &block)
    retries = 0
    begin
      block.call
    rescue => e
      retries += 1
      if retries <= max_retries
        wait_time = retries * 2 # Exponential backoff: 2, 4, 6 seconds
        Sidekiq.logger.warn "#{operation_name} failed (attempt #{retries}/#{max_retries}): #{e.message}. Retrying in #{wait_time} seconds..."
        sleep(wait_time)
        retry
      else
        Sidekiq.logger.error "#{operation_name} failed after #{max_retries} attempts: #{e.message}"
        raise e
      end
    end
  end
  
  def publish_with_retry(channel, message, max_retries: 3)
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
        Sidekiq.logger.warn "PubNub publish failed (attempt #{retries}/#{max_retries}): #{e.message}. Retrying in #{wait_time} seconds..."
        sleep(wait_time)
        retry
      else
        Sidekiq.logger.error "PubNub publish failed after #{max_retries} attempts: #{e.message}"
        raise e
      end
    end
  end
  
  def handle_quiz_error(context, error, channel = nil)
    error_message = "Knowledge Quiz error during #{context}: #{error.class} - #{error.message}"
    Sidekiq.logger.error error_message
    Sidekiq.logger.error error.backtrace.join("
")
    
    # Try to notify participants about the error
    if channel
      begin
        publish_with_retry(channel, {
          meta: "error",
          message: "Quiz experienced technical difficulties and has been stopped."
        }, max_retries: 1)
      rescue => notification_error
        Sidekiq.logger.error "Failed to notify participants of error: #{notification_error.message}"
      end
    end
  end

  # ========================================================================
  # Health monitoring and cleanup
  # ========================================================================
  
  def record_quiz_success(start_time, end_time)
    @quiz_session.set_quiz_status("Available", {
      last_success: end_time.iso8601,
      duration_seconds: (end_time - start_time).round(2),
      success_count: (@quiz_session.get_quiz_metadata["success_count"].to_i + 1)
    })
  end
  
  def cleanup_quiz_resources
    begin
      # Mark quiz as available again
      @quiz_session.set_quiz_status("Available")
    rescue => e
      Sidekiq.logger.error "Failed to set quiz status to Available: #{e.message}"
    end
    
    begin
      # Clean up any stale locks
      @quiz_session.unlock_quiz
    rescue => e
      Sidekiq.logger.error "Failed to unlock quiz: #{e.message}"
    end
    
    begin
      # Clean up execution window lock
      $redis.del("#{QUIZ_LOCK_KEY}_execution")
    rescue => e
      Sidekiq.logger.error "Failed to clean up execution lock: #{e.message}"
    end
    
    Sidekiq.logger.info "Quiz resources cleaned up"
  end

end
