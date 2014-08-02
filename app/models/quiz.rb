  #    t.integer   :user_id, :null => false
  #    t.string    :name
  #    t.text      :description
  #    t.integer   :no_questions, :default => "0"

class Quiz < ActiveRecord::Base

  # Relationships
  belongs_to :user
  has_many :quiz_questions

  # Validations
  # validates_presence_of :user_id

  def update_length

    length = 0

    for question in self.quiz_questions

      # Note that 1 is added to each of these because we put a 1 second gap between questions
      case question.question_type

        when "recitation"
          length = length + (question.passage_translations.first.last.split(" ").length * 2.5 + 15.0).to_i + 1 # 24 WPM typing speed with 15 seconds to think

        when "reference"
          length = length + 25 + 1

        when "mcq"
          length = length + 30 + 1
        end

    end

    self.quiz_length = length
  	self.save

  end

  def hours_till_start
    return (start_time - Time.now)/3600
  end

  def redis_participants
    $redis.keys("quiz#{self.id}_user*")
  end

  def redis_questions
    $redis.keys("quiz#{self.id}_qnum*")
  end

  def redis_clear_data
    redis_participants.each { |p| $redis.del(p) }
    redis_questions.each    { |q| $redis.del(q) }
  end

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

  def channel
    "quiz#{self.id}"
  end

  def status
    $redis.hmget(channel, "status").try(:first) || nil
  end

  def status=(new_status)
    return if new_status == status

    $redis.hset(channel, "status", new_status)
  end

  def announce
    broadcast = "#{self.name} is starting. <a href=\"live_quiz/#{self.id}\">Join now!</a>"
    Tweet.create(news: broadcast, user_id: 1, importance: 2)  # Admin tweet => user_id = 1
  end

  # ============= Protected below this line ==================================================================
  protected

end
