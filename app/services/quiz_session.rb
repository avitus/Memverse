# QuizSession service encapsulates all Redis operations for quiz management
# Provides a clean interface for quiz workers and controllers
# Handles connection pooling, error handling, and automatic TTL management
#
# Usage:
#   session = QuizSession.new(quiz_id)
#   session.add_participant(user_id, user_name, user_login)
#   session.update_score(user_id, question_num, score)
#   scoreboard = session.get_scoreboard
#
class QuizSession
  
  # TTL for quiz data - 2 hours
  DEFAULT_TTL = 7200
  
  # Prefix for Redis keys to avoid collisions
  KEY_PREFIX = "quiz_session"
  
  # Lock duration for preventing concurrent quiz execution (1 hour)
  LOCK_TIMEOUT = 3600
  
  # Quiz statuses
  STATUS_PENDING = "pending".freeze
  STATUS_IN_PROGRESS = "in_progress".freeze
  STATUS_FINISHED = "finished".freeze
  STATUS_FAILED = "failed".freeze
  STATUS_AVAILABLE = "available".freeze
  
  attr_reader :quiz_id
  
  def initialize(quiz_id)
    @quiz_id = quiz_id.to_i
    @redis = $redis # Use the global Redis connection for now
  end
  
  # ========================================================================
  # Participant Management
  # ========================================================================
  
  # Add a participant to the quiz session
  # @param user_id [Integer] User ID
  # @param user_name [String] Display name
  # @param user_login [String] Login/email
  # @return [Boolean] Success status
  def add_participant(user_id, user_name, user_login)
    user_key = participant_key(user_id)
    
    with_redis_error_handling("add_participant") do
      @redis.pipelined do |pipe|
        pipe.hmset(user_key, 
          'name', user_name,
          'login', user_login, 
          'id', user_id.to_s,
          'score', 0
        )
        pipe.expire(user_key, DEFAULT_TTL)
      end
      true
    end
  end
  
  # Update a user's score for a specific question
  # @param user_id [Integer] User ID
  # @param question_num [Integer] Question number (1-based)
  # @param score [Integer] Score to add (0-10)
  # @return [Boolean] Success status
  def update_score(user_id, question_num, score)
    return false unless score.to_i > 0
    
    user_key = participant_key(user_id)
    question_key = question_key(question_num)
    
    with_redis_error_handling("update_score") do
      @redis.pipelined do |pipe|
        # Update user's total score
        pipe.hincrby(user_key, 'score', score.to_i)
        pipe.expire(user_key, DEFAULT_TTL)
        
        # Update question statistics
        pipe.hincrby(question_key, 'total_score', score.to_i)
        pipe.hincrby(question_key, 'answered', 1)
        pipe.expire(question_key, DEFAULT_TTL)
      end
      true
    end
  end
  
  # Get sorted scoreboard for the quiz
  # @return [Array<Hash>] Sorted array of participant data
  def get_scoreboard
    with_redis_error_handling("get_scoreboard") do
      participant_keys = @redis.keys(participant_pattern)
      return [] if participant_keys.empty?
      
      scoreboard = []
      participant_keys.each do |key|
        participant_data = @redis.hgetall(key)
        scoreboard << participant_data unless participant_data.empty?
      end
      
      # Sort by score descending
      scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }
    end
  end
  
  # Get list of all participants
  # @return [Array<Hash>] Array of participant data
  def get_participants
    with_redis_error_handling("get_participants") do
      participant_keys = @redis.keys(participant_pattern)
      return [] if participant_keys.empty?
      
      participants = []
      participant_keys.each do |key|
        participant_data = @redis.hgetall(key)
        participants << participant_data unless participant_data.empty?
      end
      participants
    end
  end
  
  # ========================================================================
  # Question Statistics Management
  # ========================================================================
  
  # Update question metadata and statistics
  # @param question_num [Integer] Question number (1-based)
  # @param question_id [Integer] QuizQuestion ID from database
  # @param total_score [Integer] Total score for this question
  # @param answered_count [Integer] Number of users who answered
  # @return [Boolean] Success status
  def update_question_stats(question_num, question_id, total_score = nil, answered_count = nil)
    question_key = question_key(question_num)
    
    with_redis_error_handling("update_question_stats") do
      @redis.pipelined do |pipe|
        pipe.hsetnx(question_key, 'qq_id', question_id.to_s) if question_id
        pipe.hset(question_key, 'total_score', total_score.to_i) if total_score
        pipe.hset(question_key, 'answered', answered_count.to_i) if answered_count
        pipe.expire(question_key, DEFAULT_TTL)
      end
      true
    end
  end
  
  # Get all question statistics
  # @return [Array<Hash>] Array of question data
  def get_question_stats
    with_redis_error_handling("get_question_stats") do
      question_keys = @redis.keys(question_pattern)
      return [] if question_keys.empty?
      
      questions = []
      question_keys.each do |key|
        question_data = @redis.hgetall(key)
        questions << question_data unless question_data.empty?
      end
      questions
    end
  end
  
  # ========================================================================
  # Quiz Status Management
  # ========================================================================
  
  # Set the overall quiz status
  # @param status [String] One of the STATUS_* constants
  # @param metadata [Hash] Additional metadata to store
  # @return [Boolean] Success status
  def set_quiz_status(status, metadata = {})
    status_key = quiz_status_key
    
    with_redis_error_handling("set_quiz_status") do
      @redis.pipelined do |pipe|
        pipe.hset(status_key, "status", status)
        pipe.hset(status_key, "updated_at", Time.current.utc.iso8601)
        
        # Store additional metadata
        metadata.each do |key, value|
          pipe.hset(status_key, key.to_s, value.to_s)
        end
        
        pipe.expire(status_key, DEFAULT_TTL)
      end
      true
    end
  end
  
  # Get the current quiz status
  # @return [String, nil] Current status or nil if not set
  def get_quiz_status
    with_redis_error_handling("get_quiz_status") do
      @redis.hget(quiz_status_key, "status")
    end
  end
  
  # Get all quiz metadata
  # @return [Hash] All quiz status data
  def get_quiz_metadata
    with_redis_error_handling("get_quiz_metadata") do
      @redis.hgetall(quiz_status_key)
    end
  end
  
  # Check if quiz is in progress
  # @return [Boolean] True if quiz is running
  def quiz_in_progress?
    status = get_quiz_status
    status&.include?("progress") || status == STATUS_IN_PROGRESS
  end
  
  # ========================================================================
  # Lock Management for Concurrency Control
  # ========================================================================
  
  # Check if quiz is currently locked (preventing concurrent execution)
  # @return [Boolean] True if quiz is locked
  def quiz_locked?
    with_redis_error_handling("quiz_locked?") do
      @redis.exists(lock_key) == 1
    end
  end
  
  # Acquire exclusive lock for quiz execution
  # @param duration [Integer] Lock duration in seconds (default: LOCK_TIMEOUT)
  # @return [Boolean] True if lock was acquired
  def lock_quiz(duration = LOCK_TIMEOUT)
    with_redis_error_handling("lock_quiz") do
      @redis.set(lock_key, Process.pid, nx: true, ex: duration)
    end
  end
  
  # Release quiz lock
  # @return [Boolean] Success status
  def unlock_quiz
    with_redis_error_handling("unlock_quiz") do
      @redis.del(lock_key) > 0
    end
  end
  
  # ========================================================================
  # Data Cleanup and Maintenance
  # ========================================================================
  
  # Remove all quiz session data from Redis
  # @return [Boolean] Success status
  def cleanup_quiz_data
    with_redis_error_handling("cleanup_quiz_data") do
      # Get all keys related to this quiz
      keys_to_delete = []
      keys_to_delete.concat(@redis.keys(participant_pattern))
      keys_to_delete.concat(@redis.keys(question_pattern))
      keys_to_delete << quiz_status_key
      keys_to_delete << lock_key
      
      # Use pipelined deletion for better performance
      unless keys_to_delete.empty?
        @redis.pipelined do |pipe|
          keys_to_delete.each { |key| pipe.del(key) }
        end
      end
      
      true
    end
  end
  
  # Clean up expired data across all quizzes (maintenance operation)
  # This should be called periodically by a cleanup job
  # @return [Integer] Number of keys cleaned up
  def self.cleanup_expired_data
    redis = $redis
    pattern = "#{KEY_PREFIX}:*"
    
    begin
      # Get all quiz session keys
      all_keys = redis.keys(pattern)
      return 0 if all_keys.empty?
      
      # Check TTL and remove expired keys
      expired_keys = []
      all_keys.each do |key|
        ttl = redis.ttl(key)
        # TTL of -1 means no expiry set, -2 means expired/doesn't exist
        expired_keys << key if ttl == -2
      end
      
      unless expired_keys.empty?
        redis.pipelined do |pipe|
          expired_keys.each { |key| pipe.del(key) }
        end
      end
      
      expired_keys.length
    rescue Redis::BaseError => e
      Rails.logger.error "QuizSession cleanup error: #{e.message}"
      0
    end
  end
  
  # ========================================================================
  # Utility Methods for Legacy Compatibility
  # ========================================================================
  
  # Get participants using legacy key format (for backward compatibility)
  # @return [Array<String>] Array of Redis keys
  def legacy_participant_keys
    @redis.keys("user-*")
  end
  
  # Get questions using legacy key format (for backward compatibility)  
  # @return [Array<String>] Array of Redis keys
  def legacy_question_keys
    @redis.keys("qnum-*")
  end
  
  # Clean up legacy format keys (for migration)
  # @return [Boolean] Success status
  def cleanup_legacy_data
    with_redis_error_handling("cleanup_legacy_data") do
      legacy_keys = []
      legacy_keys.concat(@redis.keys("user-*"))
      legacy_keys.concat(@redis.keys("qnum-*"))
      
      unless legacy_keys.empty?
        @redis.pipelined do |pipe|
          legacy_keys.each { |key| pipe.del(key) }
        end
      end
      
      true
    end
  end
  
  private
  
  # ========================================================================
  # Private Key Generation Methods
  # ========================================================================
  
  def participant_key(user_id)
    "#{KEY_PREFIX}:#{@quiz_id}:user:#{user_id}"
  end
  
  def participant_pattern
    "#{KEY_PREFIX}:#{@quiz_id}:user:*"
  end
  
  def question_key(question_num)
    "#{KEY_PREFIX}:#{@quiz_id}:question:#{question_num}"
  end
  
  def question_pattern
    "#{KEY_PREFIX}:#{@quiz_id}:question:*"
  end
  
  def quiz_status_key
    "#{KEY_PREFIX}:#{@quiz_id}:status"
  end
  
  def lock_key
    "#{KEY_PREFIX}:#{@quiz_id}:lock"
  end
  
  # ========================================================================
  # Error Handling
  # ========================================================================
  
  def with_redis_error_handling(operation_name)
    yield
  rescue Redis::BaseError => e
    Rails.logger.error "QuizSession #{operation_name} error for quiz #{@quiz_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
    
    # Return appropriate default values
    case operation_name
    when "get_scoreboard", "get_participants", "get_question_stats"
      []
    when "get_quiz_metadata"
      {}
    when "get_quiz_status"
      nil
    when "quiz_locked?", "quiz_in_progress?"
      false
    else
      false
    end
  rescue => e
    Rails.logger.error "QuizSession unexpected error in #{operation_name} for quiz #{@quiz_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Return safe defaults
    case operation_name
    when "get_scoreboard", "get_participants", "get_question_stats"
      []
    when "get_quiz_metadata"
      {}
    when "get_quiz_status"
      nil
    when "quiz_locked?", "quiz_in_progress?"
      false
    else
      false
    end
  end
end