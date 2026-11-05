# QuizSession service optimized to fix production stalling issue
# Replaces KEYS command with Redis Sets for O(1) performance
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

  # Length of the tweets.news column
  ANNOUNCEMENT_MAX_LENGTH = 255

  # Extra time to accept an answer after the player's timer ends, to cover network
  # delay. The correct answer is not published until this has passed.
  ANSWER_GRACE_SECONDS = 2

  # How long the correct answer stays on screen before the next question
  ANSWER_REVEAL_SECONDS = 4

  # Runs as one step in Redis, so a score is either saved before the question closes or not at all,
  # and a claimed answer can't be left without its points.
  # KEYS: question hash, user hash. ARGV: claim field, score, now, TTL.
  RECORD_ANSWER_SCRIPT = <<~LUA.freeze
    local closes_at = tonumber(redis.call('HGET', KEYS[1], 'closes_at'))
    if not closes_at or tonumber(ARGV[3]) > closes_at then return 'closed' end
    if redis.call('HSETNX', KEYS[1], ARGV[1], '1') == 0 then return 'duplicate' end

    local score = tonumber(ARGV[2])
    if score > 0 then
      redis.call('HINCRBY', KEYS[2], 'score', score)
      redis.call('EXPIRE', KEYS[2], ARGV[4])
      redis.call('HINCRBY', KEYS[1], 'total_score', score)
      redis.call('HINCRBY', KEYS[1], 'answered', 1)
    end
    redis.call('EXPIRE', KEYS[1], ARGV[4])
    return 'graded'
  LUA

  attr_reader :quiz_id

  # Everyone on the top score, ordered by name. Nobody wins if nobody scored.
  # @param scoreboard [Array<Hash>] Participant data from get_scoreboard
  # @return [Array<Hash>] The winners; more than one means a tie
  def self.winners(scoreboard)
    top_score = scoreboard.map { |participant| participant['score'].to_i }.max.to_i
    return [] unless top_score.positive?

    scoreboard
      .select { |participant| participant['score'].to_i == top_score }
      .sort_by { |participant| participant['name'].to_s.downcase }
  end

  # @param winners [Array<Hash>] At least one participant, from QuizSession.winners
  # @param quiz_name [String] Name of the quiz as it should read in the sentence
  # @return [Array<String>] News items for the dashboard. A tie too long for one item
  #   is split over several, so that every winner is named.
  def self.winner_announcements(winners, quiz_name)
    # News items are shown as HTML and players choose their own names
    names = winners.map { |winner| ERB::Util.html_escape(winner['name'].to_s).to_str }
    return ["#{names.first} won #{quiz_name}".truncate(ANNOUNCEMENT_MAX_LENGTH)] if names.one?

    ending = " tied for first in #{quiz_name}"
    room = ANNOUNCEMENT_MAX_LENGTH - ending.length
    batches = names.each_with_object([[]]) do |name, groups|
      groups << [] if groups.last.any? && [*groups.last, name].to_sentence.length > room
      groups.last << name
    end
    batches.map { |batch| "#{batch.to_sentence}#{ending}".truncate(ANNOUNCEMENT_MAX_LENGTH) }
  end

  def initialize(quiz_id)
    @quiz_id = quiz_id.to_i
    @redis = $redis # Use the global Redis connection for now
  end

  # ========================================================================
  # Participant Management
  # ========================================================================

  # Add a participant to the quiz session (only if not already exists)
  # @param user_id [Integer] User ID
  # @param user_name [String] Display name
  # @param user_login [String] Login/email
  # @return [Boolean] Success status
  def add_participant(user_id, user_name, user_login)
    user_key = participant_key(user_id)

    with_redis_error_handling("add_participant") do
      # Check if participant already exists
      exists = @redis.exists(user_key)

      @redis.pipelined do |pipe|
        # Redis.exists returns 1 if key exists, 0 if not
        unless exists == 1
          pipe.hmset(user_key,
            'name', user_name,
            'login', user_login,
            'id', user_id.to_s,
            'score', 0
          )
        end
        pipe.expire(user_key, DEFAULT_TTL)
        # Add to participant set for efficient retrieval. This also runs for an existing
        # participant, because an earlier attempt may have stopped after creating the hash.
        pipe.sadd(participant_set_key, user_id.to_s)
        pipe.expire(participant_set_key, DEFAULT_TTL)
      end
      true
    end
  end

  # Get sorted scoreboard for the quiz
  # @param raise_errors [Boolean] Raise on a Redis failure instead of returning an empty scoreboard.
  #   Deciding the winner needs this, because an empty scoreboard means nobody played.
  # @return [Array<Hash>] Sorted array of participant data
  def get_scoreboard(raise_errors: false)
    return read_scoreboard if raise_errors

    with_redis_error_handling("get_scoreboard") { read_scoreboard }
  end

  # Get list of all participants
  # @return [Array<Hash>] Array of participant data
  def get_participants
    with_redis_error_handling("get_participants") do
      participant_ids = @redis.smembers(participant_set_key)
      return [] if participant_ids.empty?

      participants = []
      @redis.pipelined do |pipe|
        participant_ids.each do |user_id|
          pipe.hgetall(participant_key(user_id))
        end
      end.each_with_index do |participant_data, index|
        unless participant_data.empty?
          participant_data['id'] ||= participant_ids[index]
          participants << participant_data
        end
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
        # Track question in set
        pipe.sadd(question_set_key, question_num.to_s)
        pipe.expire(question_set_key, DEFAULT_TTL)
      end
      true
    end
  end

  # Start accepting answers to a question
  # @param question_num [Integer] Position of the question in the quiz
  # @param question_id [Integer] ID of the QuizQuestion being asked
  # @param time_allocated [Integer] Seconds shown on the player's timer
  # @return [Boolean] Success status
  def open_question(question_num, question_id, time_allocated)
    key = question_key(question_num)

    # A Redis failure raises, so that a question nobody could answer is never published
    @redis.pipelined do |pipe|
      pipe.hset(key, 'qq_id', question_id.to_s)
      pipe.hset(key, 'closes_at', closing_time(time_allocated).to_s)
      pipe.expire(key, DEFAULT_TTL)
      pipe.sadd(question_set_key, question_num.to_s)
      pipe.expire(question_set_key, DEFAULT_TTL)
    end
  end

  # Give players their full time from now. Call this once the question has been published,
  # because each browser starts its countdown when the question arrives, so time spent
  # publishing must not come off the deadline.
  # @param question_num [Integer] Position of the question in the quiz
  # @param time_allocated [Integer] Seconds players are given to answer
  def restart_answer_window(question_num, time_allocated)
    @redis.hset(question_key(question_num), 'closes_at', closing_time(time_allocated).to_s)
  end

  # @param question_num [Integer] Position of the question in the quiz
  # @return [String, nil] ID of the QuizQuestion if it is still accepting answers
  # A Redis failure raises, because "closed" would tell the player not to try again.
  def open_question_id(question_num)
    question_id, closes_at = @redis.hmget(question_key(question_num), 'qq_id', 'closes_at')
    question_id if closes_at && Time.current.to_f <= closes_at.to_f
  end

  # Save the user's one answer to a question and its score, if the question is still open.
  # A Redis failure raises rather than being swallowed, because nothing was saved and the
  # player can send the answer again.
  # @param question_num [Integer] Position of the question in the quiz
  # @param user_id [Integer] User ID
  # @param score [Integer] Points for the answer (0-10)
  # @return [Symbol] :graded, :closed or :duplicate
  def record_answer(question_num, user_id, score)
    @redis.eval(
      RECORD_ANSWER_SCRIPT,
      keys: [question_key(question_num), participant_key(user_id)],
      argv: ["answered_by:#{user_id}", score.to_i, Time.current.to_f, DEFAULT_TTL]
    ).to_sym
  end

  # Get all question statistics
  # @return [Array<Hash>] Array of question data
  def get_question_stats
    with_redis_error_handling("get_question_stats") do
      question_nums = @redis.smembers(question_set_key)
      return [] if question_nums.empty?

      questions = []
      @redis.pipelined do |pipe|
        question_nums.each do |q_num|
          pipe.hgetall(question_key(q_num))
        end
      end.each do |question_data|
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

  # Check if quiz is in progress (questions actively running)
  # @return [Boolean] True if quiz questions are actively being asked
  def quiz_in_progress?
    status = get_quiz_status
    return false if status.nil?

    # Only consider quiz in progress when questions are actually running
    # Chat period ("Chat open. Wait for question.") is not considered "in progress" for display purposes
    # Initializing state is also not considered "in progress" (it's "preparing")
    status.match?(/Question \d+ in progress/)
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
      # Get participant and question IDs from sets
      participant_ids = @redis.smembers(participant_set_key)
      question_nums = @redis.smembers(question_set_key)

      # Build list of keys to delete
      keys_to_delete = []

      # Add participant keys
      participant_ids.each do |user_id|
        keys_to_delete << participant_key(user_id)
      end

      # Add question keys
      question_nums.each do |q_num|
        keys_to_delete << question_key(q_num)
      end

      # Add set keys and status keys
      keys_to_delete << participant_set_key
      keys_to_delete << question_set_key
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
      # Use SCAN instead of KEYS for production safety
      cursor = "0"
      expired_keys = []

      loop do
        cursor, keys = redis.scan(cursor, match: pattern, count: 100)

        keys.each do |key|
          ttl = redis.ttl(key)
          # TTL of -1 means no expiry set, -2 means expired/doesn't exist
          expired_keys << key if ttl == -2
        end

        break if cursor == "0"
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
    # Use SCAN instead of KEYS for safety
    keys = []
    cursor = "0"

    loop do
      cursor, batch = @redis.scan(cursor, match: "user-*", count: 100)
      keys.concat(batch)
      break if cursor == "0"
    end

    keys
  end

  # Get questions using legacy key format (for backward compatibility)
  # @return [Array<String>] Array of Redis keys
  def legacy_question_keys
    # Use SCAN instead of KEYS for safety
    keys = []
    cursor = "0"

    loop do
      cursor, batch = @redis.scan(cursor, match: "qnum-*", count: 100)
      keys.concat(batch)
      break if cursor == "0"
    end

    keys
  end

  # Clean up legacy format keys (for migration)
  # @return [Boolean] Success status
  def cleanup_legacy_data
    with_redis_error_handling("cleanup_legacy_data") do
      legacy_keys = []
      legacy_keys.concat(legacy_participant_keys)
      legacy_keys.concat(legacy_question_keys)

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

  def closing_time(time_allocated)
    Time.current.to_f + time_allocated + ANSWER_GRACE_SECONDS
  end

  def read_scoreboard
    # Get participant IDs from the set (O(n) where n is participants, not all Redis keys)
    participant_ids = @redis.smembers(participant_set_key)
    return [] if participant_ids.empty?

    scoreboard = []
    # Use pipelining for efficiency
    @redis.pipelined do |pipe|
      participant_ids.each do |user_id|
        pipe.hgetall(participant_key(user_id))
      end
    end.each_with_index do |participant_data, index|
      unless participant_data.empty?
        # Ensure we have the user_id in the data
        participant_data['id'] ||= participant_ids[index]
        scoreboard << participant_data
      end
    end

    # Sort by score descending; name keeps tied participants in a stable order
    scoreboard.sort_by { |participant| [-participant['score'].to_i, participant['name'].to_s.downcase] }
  end

  def participant_key(user_id)
    "#{KEY_PREFIX}:#{@quiz_id}:user:#{user_id}"
  end

  def participant_set_key
    "#{KEY_PREFIX}:#{@quiz_id}:participants"
  end

  def question_key(question_num)
    "#{KEY_PREFIX}:#{@quiz_id}:question:#{question_num}"
  end

  def question_set_key
    "#{KEY_PREFIX}:#{@quiz_id}:questions"
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