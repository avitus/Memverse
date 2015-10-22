  #    t.integer   :user_id, :null => false
  #    t.string    :name
  #    t.text      :description
  #    t.integer   :no_questions, :default => "0"

class Quiz < ActiveRecord::Base

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
  belongs_to :user
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
  # @return [Fixnum]
  def hours_till_start
    return (start_time - Time.now)/3600
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

  # ============= Protected below this line ==================================================================
  protected

end
