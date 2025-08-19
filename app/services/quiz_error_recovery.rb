# QuizErrorRecovery service provides fallback mechanisms and error recovery
# for live quiz functionality when PubNub or other dependencies fail
class QuizErrorRecovery
  include ActiveSupport::Rescuable
  
  # Recovery strategies
  RECOVERY_STRATEGIES = {
    pubnub_failure: :use_polling_fallback,
    redis_failure: :use_database_fallback,
    network_timeout: :retry_with_backoff,
    quiz_locked: :wait_and_retry,
    data_corruption: :rebuild_from_logs
  }.freeze
  
  # Maximum retry attempts for different error types
  MAX_RETRIES = {
    network: 5,
    database: 3,
    pubnub: 10,
    redis: 5
  }.freeze
  
  attr_reader :quiz_id, :error_log, :recovery_attempts
  
  def initialize(quiz_id)
    @quiz_id = quiz_id
    @error_log = []
    @recovery_attempts = Hash.new(0)
    @quiz_session = QuizSession.new(quiz_id)
  end
  
  # Main error recovery entry point
  def recover_from_error(error, context = {})
    log_error(error, context)
    
    strategy = determine_recovery_strategy(error)
    
    if can_recover?(strategy)
      execute_recovery(strategy, error, context)
    else
      handle_unrecoverable_error(error, context)
    end
  end
  
  # Graceful degradation when PubNub fails
  def handle_pubnub_failure(error, context = {})
    Rails.logger.error "PubNub failure for quiz #{quiz_id}: #{error.message}"
    
    # Notify participants via alternative channel if possible
    notify_via_email(context[:participants]) if context[:participants]
    
    # Switch to polling-based updates
    enable_polling_mode
    
    # Store messages for later delivery
    queue_messages_for_retry(context[:pending_messages])
    
    # Alert admins
    notify_admins_of_failure(error, 'PubNub')
    
    { success: true, fallback: :polling, message: 'Switched to polling mode' }
  rescue => e
    Rails.logger.error "Failed to handle PubNub failure: #{e.message}"
    { success: false, error: e.message }
  end
  
  # Fallback to database when Redis fails
  def handle_redis_failure(error, context = {})
    Rails.logger.error "Redis failure for quiz #{quiz_id}: #{error.message}"
    
    # Use database for score storage
    migrate_scores_to_database(context[:scores]) if context[:scores]
    
    # Use database for session management
    create_database_session
    
    # Continue quiz with database backend
    { success: true, fallback: :database, message: 'Using database for score tracking' }
  rescue => e
    Rails.logger.error "Failed to handle Redis failure: #{e.message}"
    { success: false, error: e.message }
  end
  
  # Automatic quiz rescheduling on failure
  def reschedule_quiz(original_start_time, reason = 'System failure')
    new_start_time = calculate_next_available_slot(original_start_time)
    
    quiz = Quiz.find(quiz_id)
    quiz.update!(
      start_time: new_start_time,
      status: 'rescheduled',
      reschedule_reason: reason
    )
    
    # Notify participants of rescheduling
    notify_participants_of_reschedule(quiz, new_start_time, reason)
    
    # Create audit log
    create_reschedule_audit(quiz, original_start_time, new_start_time, reason)
    
    new_start_time
  rescue => e
    Rails.logger.error "Failed to reschedule quiz #{quiz_id}: #{e.message}"
    nil
  end
  
  # Health check and auto-recovery
  def perform_health_check
    checks = {
      redis: check_redis_health,
      pubnub: check_pubnub_health,
      database: check_database_health,
      workers: check_worker_health
    }
    
    failed_components = checks.select { |_, healthy| !healthy }.keys
    
    if failed_components.any?
      initiate_auto_recovery(failed_components)
    end
    
    {
      healthy: failed_components.empty?,
      failed_components: failed_components,
      checks: checks
    }
  end
  
  # Rebuild quiz state from transaction logs
  def rebuild_quiz_state
    Rails.logger.info "Rebuilding quiz state for quiz #{quiz_id}"
    
    # Clear potentially corrupted data
    @quiz_session.cleanup_quiz_data
    
    # Rebuild from database records
    quiz = Quiz.find(quiz_id)
    participants = quiz.participants
    
    # Restore participant data
    participants.each do |participant|
      @quiz_session.add_participant(
        participant.user_id,
        participant.user.name_or_login,
        participant.user.login
      )
      
      # Restore scores from database backup
      if participant.score > 0
        @quiz_session.update_score(participant.user_id, nil, participant.score)
      end
    end
    
    # Restore question stats
    quiz.quiz_questions.each_with_index do |question, index|
      @quiz_session.update_question_stats(
        index + 1,
        question.id,
        question.total_score,
        question.answered_count
      )
    end
    
    Rails.logger.info "Successfully rebuilt quiz state for quiz #{quiz_id}"
    true
  rescue => e
    Rails.logger.error "Failed to rebuild quiz state: #{e.message}"
    false
  end
  
  # Create admin alerts for failures
  def create_admin_alert(error_type, details)
    AdminAlert.create!(
      alert_type: 'quiz_failure',
      severity: determine_severity(error_type),
      title: "Quiz System Error: #{error_type}",
      message: details[:message],
      metadata: {
        quiz_id: quiz_id,
        error_type: error_type,
        timestamp: Time.current,
        recovery_attempted: details[:recovery_attempted],
        recovery_successful: details[:recovery_successful]
      }
    )
    
    # Send immediate notification to admins
    AdminMailer.quiz_failure_alert(quiz_id, error_type, details).deliver_later
  rescue => e
    Rails.logger.error "Failed to create admin alert: #{e.message}"
  end
  
  private
  
  def log_error(error, context)
    @error_log << {
      error: error,
      context: context,
      timestamp: Time.current,
      backtrace: error.backtrace&.first(5)
    }
    
    Rails.logger.error "Quiz #{quiz_id} error: #{error.message}"
    Rails.logger.error "Context: #{context.inspect}"
  end
  
  def determine_recovery_strategy(error)
    case error
    when Redis::BaseError
      RECOVERY_STRATEGIES[:redis_failure]
    when Net::ReadTimeout, Net::OpenTimeout
      RECOVERY_STRATEGIES[:network_timeout]
    when PubNub::Error
      RECOVERY_STRATEGIES[:pubnub_failure]
    else
      :unknown
    end
  end
  
  def can_recover?(strategy)
    return false if strategy == :unknown
    
    error_type = strategy.to_s.split('_').first.to_sym
    max_retries = MAX_RETRIES[error_type] || 3
    
    @recovery_attempts[strategy] < max_retries
  end
  
  def execute_recovery(strategy, error, context)
    @recovery_attempts[strategy] += 1
    
    case strategy
    when :use_polling_fallback
      handle_pubnub_failure(error, context)
    when :use_database_fallback
      handle_redis_failure(error, context)
    when :retry_with_backoff
      retry_with_exponential_backoff(error, context)
    when :wait_and_retry
      wait_for_lock_release(context)
    when :rebuild_from_logs
      rebuild_quiz_state
    else
      { success: false, error: 'Unknown recovery strategy' }
    end
  end
  
  def handle_unrecoverable_error(error, context)
    Rails.logger.error "Unrecoverable error for quiz #{quiz_id}: #{error.message}"
    
    # Mark quiz as failed
    @quiz_session.set_quiz_status(QuizSession::STATUS_FAILED, {
      error: error.message,
      context: context.to_json
    })
    
    # Create admin alert
    create_admin_alert('unrecoverable_error', {
      message: error.message,
      recovery_attempted: true,
      recovery_successful: false
    })
    
    # Attempt to notify participants
    notify_participants_of_failure
    
    { success: false, error: 'Quiz failed and cannot be recovered' }
  end
  
  def enable_polling_mode
    Rails.cache.write("quiz:#{quiz_id}:polling_mode", true, expires_in: 2.hours)
  end
  
  def queue_messages_for_retry(messages)
    return unless messages&.any?
    
    messages.each do |message|
      QuizMessageRetryJob.perform_later(quiz_id, message)
    end
  end
  
  def notify_admins_of_failure(error, component)
    User.admin.find_each do |admin|
      AdminMailer.component_failure_alert(
        admin,
        component,
        error.message,
        quiz_id
      ).deliver_later
    end
  end
  
  def migrate_scores_to_database(scores)
    return unless scores
    
    scores.each do |user_id, score|
      QuizParticipant.find_or_create_by(
        quiz_id: quiz_id,
        user_id: user_id
      ).update!(score: score)
    end
  end
  
  def create_database_session
    QuizDatabaseSession.create!(
      quiz_id: quiz_id,
      status: 'active',
      fallback_mode: true,
      started_at: Time.current
    )
  end
  
  def calculate_next_available_slot(original_time)
    # Add 30 minutes to original time
    next_slot = original_time + 30.minutes
    
    # Check if slot is available
    while Quiz.where(start_time: (next_slot - 5.minutes)..(next_slot + 5.minutes)).exists?
      next_slot += 10.minutes
    end
    
    next_slot
  end
  
  def notify_participants_of_reschedule(quiz, new_time, reason)
    quiz.participants.includes(:user).find_each do |participant|
      UserMailer.quiz_rescheduled(
        participant.user,
        quiz,
        new_time,
        reason
      ).deliver_later
    end
  end
  
  def notify_participants_of_failure
    quiz = Quiz.find(quiz_id)
    participants = quiz.participants.includes(:user)
    
    participants.find_each do |participant|
      UserMailer.quiz_failure_notification(
        participant.user,
        quiz
      ).deliver_later
    end
  rescue => e
    Rails.logger.error "Failed to notify participants: #{e.message}"
  end
  
  def create_reschedule_audit(quiz, original_time, new_time, reason)
    QuizAuditLog.create!(
      quiz_id: quiz.id,
      action: 'rescheduled',
      original_time: original_time,
      new_time: new_time,
      reason: reason,
      performed_at: Time.current
    )
  end
  
  def retry_with_exponential_backoff(error, context, attempt = 1)
    delay = 2 ** attempt
    Rails.logger.info "Retrying after #{delay} seconds (attempt #{attempt})"
    
    sleep(delay)
    
    # Retry the original operation
    yield if block_given?
    
    { success: true, retries: attempt }
  rescue => e
    if attempt < 5
      retry_with_exponential_backoff(e, context, attempt + 1)
    else
      { success: false, error: 'Max retries exceeded' }
    end
  end
  
  def wait_for_lock_release(context)
    max_wait = 60 # seconds
    waited = 0
    
    while @quiz_session.quiz_locked? && waited < max_wait
      sleep(5)
      waited += 5
    end
    
    if waited >= max_wait
      { success: false, error: 'Lock timeout exceeded' }
    else
      { success: true, waited: waited }
    end
  end
  
  def check_redis_health
    $redis.ping == 'PONG'
  rescue
    false
  end
  
  def check_pubnub_health
    # Simplified health check - in production would test actual connection
    true
  rescue
    false
  end
  
  def check_database_health
    ActiveRecord::Base.connection.active?
  rescue
    false
  end
  
  def check_worker_health
    Sidekiq::ProcessSet.new.size > 0
  rescue
    false
  end
  
  def initiate_auto_recovery(failed_components)
    failed_components.each do |component|
      case component
      when :redis
        restart_redis_connection
      when :pubnub
        reinitialize_pubnub
      when :database
        reconnect_database
      when :workers
        restart_sidekiq_workers
      end
    end
  end
  
  def restart_redis_connection
    $redis.disconnect!
    $redis = Redis.new(Rails.application.config_for(:redis))
  rescue => e
    Rails.logger.error "Failed to restart Redis: #{e.message}"
  end
  
  def reinitialize_pubnub
    # Re-initialize PubNub client
    Rails.application.config.pubnub_client = nil
    Rails.application.config.pubnub_client = PubNub.new(
      publish_key: ENV['PUBNUB_PUBLISH_KEY'],
      subscribe_key: ENV['PUBNUB_SUBSCRIBE_KEY']
    )
  rescue => e
    Rails.logger.error "Failed to reinitialize PubNub: #{e.message}"
  end
  
  def reconnect_database
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.establish_connection
  rescue => e
    Rails.logger.error "Failed to reconnect database: #{e.message}"
  end
  
  def restart_sidekiq_workers
    # This would typically be handled by process manager
    Rails.logger.warn "Sidekiq workers need manual restart"
  end
  
  def determine_severity(error_type)
    case error_type
    when 'unrecoverable_error', 'data_corruption'
      'critical'
    when 'pubnub_failure', 'redis_failure'
      'high'
    when 'network_timeout', 'quiz_locked'
      'medium'
    else
      'low'
    end
  end
  
  def notify_via_email(participants)
    return unless participants
    
    participants.each do |participant|
      UserMailer.quiz_fallback_notification(
        participant,
        quiz_id,
        'Real-time updates temporarily unavailable. Please refresh your browser.'
      ).deliver_later
    end
  end
end