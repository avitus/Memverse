class KnowledgeQuiz

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include IceCube

  sidekiq_options :retry => false # Don't retry quiz if something goes wrong

  recurrence do
     # weekly.day_of_week(2).hour_of_day(9)   # Every Tuesday at 9am
     daily.hour_of_day(9,11,15,18,21)         # 9am, 11am, 3pm, 6pm, 9pm each day
     # minutely(10)                           # For development
  end

  def perform

    # Update start time for next quiz
    schedule = IceCube::Schedule.new( Time.now )
    schedule.add_recurrence_rule( IceCube::Rule.hourly )
    next_quiz_time = schedule.next_occurrence

    # Start quiz
    puts "===> Opening quiz room at " + Time.now.to_s

    # Clear participant and question scores from Redis
    participants = $redis.keys("user-*")       # user ID's
    questions    = $redis.keys("qnum-*")       # question numbers
    participants.each { |p| $redis.del(p) }
    questions.each    { |q| $redis.del(q) }

    # Save status of quiz in redis
    $redis.hset("quiz-bible-knowledge", "status", "In progress. Wait for question.")

    # Select quiz and set up PubNub channel
    quiz    = Quiz.find(1)
    channel = "quiz-1"  # General knowledge quiz will always have ID=1

    # PubNub callback function - From version 3.4 PubNub is fully asynchronous
    @my_callback = lambda { |message|
        if message[0]  # Return codes are of form [1,"Sent","136074940..."]
            puts("Successfully Sent Message!");
        else
            # If message is not sent we should probably try to send it again
            puts("!!!!! Failed to send message !!!!!!")
        end
    }

    # Open quiz chat channel
    puts "===> Opening chat at " + Time.now.to_s
    if $redis.exists("chat-#{channel}")
      status = $redis.hmget("chat-#{channel}", "status").first
    end

    unless status && status == "Open"
      new_status = "Open"
      $redis.hset("chat-#{channel}", "status", new_status)
      PN.publish( :channel  => channel, :message  => {
          :meta => "chat_status",
          :status => new_status
        },
        :callback => @my_callback
      )
    end

    # Allow time for chatting
    sleep(60)  # 1 minute

    # Set up number of questions
    q_num_array = Array(1..10)

    puts "===> Starting quiz at " + Time.now.to_s
    # Iterate through questions
    q_num_array.each do |q_num|

      puts "===> Question: " + q_num.to_s

      # Pick a question at random
      q = QuizQuestion.mcq.fresh.sort_by{ rand }.first

      # Update question to show that it was asked today
      q.update_attribute( :last_asked, Date.today )

      # Publish question
      PN.publish( :channel  => channel, :message  => {
          :meta        => "question",
          :q_id        => q.id,
          :q_num       => q_num,
          :q_type      => "mcq",
          :mc_question => q.mc_question,
          :mc_option_a => q.mc_option_a,
          :mc_option_b => q.mc_option_b,
          :mc_option_c => q.mc_option_c,
          :mc_option_d => q.mc_option_d,
          :mc_answer   => q.mc_answer,
          :time_alloc  => q.time_allocation
        },
        :callback => @my_callback
      )

      # Time to answer question
      sleep( q.time_allocation )

      # Update scoreboard
      puts "===> Updating scoreboard"

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
    puts "===> Finished quiz at " + Time.now.to_s

    # Update start time for next quiz
    quiz.update_attribute(:start_time, next_quiz_time)
    puts "Next knowledge quiz will start at " + next_quiz_time.to_s

    # Update difficulty for all questions
    quiz_table = Array.new
    quiz_questions = $redis.keys("qnum-*")
    quiz_questions.each do |qq|
      quiz_table << $redis.hgetall(qq)
    end

    puts '----------------------------------------------------------------------------------------'
    puts '#  |  ID  |  Answers Submitted  |  Total Score'
    puts '----------------------------------------------------------------------------------------'
    quiz_table.each_with_index do |qq, index|

      q_id           = qq['qq_id'].to_i             # Quiz question ID
      q_count        = qq['answered'].to_i          # Number of people who answered this question
      q_total        = qq['total_score'].to_i       # Total score, 10 = max
      q_perc_correct = q_total.to_f / q_count * 10  # Calculate score as a %

      puts index.to_s + "      " + qq['qq_id'] + "         " + qq['answered'] + "                  " + qq['total_score']

      # Update quiz question difficulty in database
      question = QuizQuestion.find( q_id )
      question.update_difficulty( q_count, q_perc_correct )

    end

    ### Close chat 10 minutes after quiz
    puts "Quiz now over. Sleeping for 10 minutes, then shutting down chat."
    sleep(60)

    new_status = "Closed"
    $redis.hset("chat-#{channel}", "status", new_status)
    PN.publish( :channel  => channel, :message  => {
        :meta => "chat_status",
        :status => new_status
      },
      :callback => @my_callback
    )

    puts "Chat closed and rake task finished."

  end

end
