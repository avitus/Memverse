class KnowledgeQuiz

  include Sidekiq::Worker
  # include Sidetiq::Schedulable

  # recurrence do
  #   weekly.day_of_week(2).hour_of_day(9)   # Every Tuesday at 9am
  # end

  def perform

    # Clear participant scores from Redis
    participants = $redis.keys("user-*")
    participants.each { |p| $redis.del(p) }

    # Save status of quiz in redis
    $redis.hset("quiz-bible-knowledge", "status", "In progress. Wait for question.")

    # Set up number of questions
    q_num_array = Array(1..10)

    # Iterate through questions
    q_num_array.each do |q_num|

      # Pick a question at random
      q = QuizQuestion.where(:question_type => 'MCQ').sort_by{ rand }.first

      # Publish question
      PN.publish( :channel  => channel, :message  => {
          :meta => "question",
          :q_num => q_num,
          :q_type => "mcq",
          :mc_question => q.mc_question,
          :mc_option_a => q.mc_option_a,
          :mc_option_b => q.mc_option_b,
          :mc_option_c => q.mc_option_c,
          :mc_option_d => q.mc_option_d,
          :mc_answer => q.mc_answer,
          :time_alloc => 30
        },
        :callback => @my_callback
      )

      # Time to answer question
      sleep(30)

      # Update scoreboard
      scoreboard = Array.new
      participants = $redis.keys("user-*")
      participants.each { |p| scoreboard << $redis.hgetall(p) }
      scoreboard = scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

      # Publish scoreboard
      PN.publish( :channel  => channel, :message  => {
          :meta => "scoreboard",
          :scoreboard => scoreboard
        },
        :callback => @my_callback
      )

    end # of question loop

    # Update quiz status in redis
    $redis.hset("quiz-bible-knowledge", "status", "Finished")
    puts "Quiz complete"


  end

end
