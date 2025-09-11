  #    t.integer   :user_id, :null => false
  #    t.string    :name
  #    t.text      :description
  #    t.integer   :no_questions, :default => "0"

class Quiz < ApplicationRecord

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :Quiz do
    key :required, [:id, :name, :description, :start_time, :quiz_length, :quiz_questions_count]
    property :id do
      key :type, :integer
      key :format, :int64
    end   
    property :name do
      key :type, :string
    end 
    property :description do
      key :type, :string
    end 
    property :quiz_questions_count do
      key :type, :integer
      key :format, :int64
    end 
    property :quiz_length do
      key :type, :integer
      key :format, :int64
    end 
    property :start_time do
      key :type, :string
      key :format, :dateTime
    end           
  end

  swagger_schema :Quiz do
    allOf do
      schema do
        key :'$ref', :Quiz
      end
      schema do
        key :required, [:id, :name, :description, :start_time, :quiz_length, :quiz_questions_count]
        property :id do
          key :type, :integer
          key :format, :int64
        end
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------


  # Relationships
  belongs_to :user, optional: true
  has_many :quiz_questions

  # Validations
  # validates_presence_of :user_id

  # Update length for quiz
  # Uses {QuizQuestion#time_alloc} to determine length of each question.
  # @return [void]
  def update_length
    length = 0

    for question in self.quiz_questions
      # We put a 1 second gap between questions
      length += question.time_alloc + 1
    end

    self.quiz_length = length
  	self.save
  end

  # Hours till quiz starts
  # @return [Integer]
  def hours_till_start
    return nil unless start_time
    return (start_time - Time.current)/3600
  end

  # Quiz participants from redis
  def redis_participants
    $redis.keys("quiz#{self.id}_user*")
  end

  def redis_questions
    $redis.keys("quiz#{self.id}_qnum*")
  end

  # Clear quiz data from redis
  def redis_clear_data
    redis_participants.each { |p| $redis.del(p) }
    redis_questions.each    { |q| $redis.del(q) }
  end

  # Publish scoreboard via PubNub
  # @return [void]
  def publish_scoreboard
    scoreboard = Array.new

    self.redis_participants.each { |p| scoreboard << $redis.hgetall(p) }

    scoreboard = scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

    PN.publish(
      channel: self.channel,
      message: {
        meta: "scoreboard",
        scoreboard: scoreboard
      },
      http_sync: true,
      callback: PN_CALLBACK
    )
  end

  # PubNub channel for quiz
  # @return [String]
  def channel
    "quiz#{self.id}"
  end

  # Quiz status
  # @return [String, nil]
  def status
    $redis.hmget(channel, "status").try(:first) || nil
  end

  # Update quiz status
  # @return [void]
  def status=(new_status)
    return if new_status == status

    $redis.hset(channel, "status", new_status)
  end

  # Announce quiz start with a Tweet
  # @return [void]
  def announce
    broadcast = "#{self.name} is starting. <a href=\"live_quiz/#{self.id}\">Join now!</a>"
    Tweet.create(news: broadcast, user_id: 1, importance: 2)  # Admin tweet => user_id = 1
  end

  # Get QuizSession service instance for this quiz
  # @return [QuizSession]
  def quiz_session
    @quiz_session ||= QuizSession.new(self.id)
  end

  # Get scoreboard using QuizSession service (new method)
  # @return [Array<Hash>] Sorted scoreboard
  def scoreboard
    quiz_session.get_scoreboard
  end

  # Get participants using QuizSession service (new method)
  # @return [Array<Hash>] Array of participant data
  def participants
    quiz_session.get_participants
  end

  # Check if quiz is currently locked
  # @return [Boolean]
  def locked?
    quiz_session.quiz_locked?
  end

  # Lock quiz for exclusive access
  # @param duration [Integer] Lock duration in seconds
  # @return [Boolean] Success status
  def lock!(duration = QuizSession::LOCK_TIMEOUT)
    quiz_session.lock_quiz(duration)
  end

  # Unlock quiz
  # @return [Boolean] Success status
  def unlock!
    quiz_session.unlock_quiz
  end

  # Check if quiz is in progress using QuizSession service
  # @return [Boolean]
  def in_progress?
    quiz_session.quiz_in_progress?
  end

  # Set quiz status using QuizSession service
  # @param new_status [String] Status to set
  # @param metadata [Hash] Additional metadata
  # @return [Boolean] Success status
  def set_status(new_status, metadata = {})
    quiz_session.set_quiz_status(new_status, metadata)
  end

  # Clean up all quiz session data
  # @return [Boolean] Success status
  def cleanup_session_data!
    quiz_session.cleanup_quiz_data
  end

  # Get human-readable schedule for knowledge quiz
  # @return [Array<String>] Array of schedule descriptions
  def self.knowledge_quiz_schedule
    require 'ice_cube'
    
    # Use the same schedule as KnowledgeQuiz worker
    schedule = IceCube::Schedule.new(Time.current.utc)
    # Tuesday at 17:00 UTC
    schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:tuesday).hour_of_day(17).minute_of_hour(0).second_of_minute(0))
    # Saturday at 23:00 UTC
    schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:saturday).hour_of_day(23).minute_of_hour(0).second_of_minute(0))
    
    # Get next few occurrences to determine the pattern
    occurrences = schedule.next_occurrences(2)
    
    # Convert to human-readable format with timezone
    occurrences.map do |time|
      # Convert UTC to Pacific Time
      pacific_time = time.in_time_zone("America/Los_Angeles")
      pacific_time.strftime("%As at %-l%P (%Z)")
    end
  end

  # Get next quiz time for knowledge quiz
  # @return [Time] Next scheduled quiz time
  def self.next_knowledge_quiz_time
    require 'ice_cube'
    
    schedule = IceCube::Schedule.new(Time.current.utc)
    # Tuesday at 17:00 UTC
    schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:tuesday).hour_of_day(17).minute_of_hour(0).second_of_minute(0))
    # Saturday at 23:00 UTC
    schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:saturday).hour_of_day(23).minute_of_hour(0).second_of_minute(0))
    
    schedule.next_occurrence
  end

  # ============= Protected below this line ==================================================================
  protected

end
