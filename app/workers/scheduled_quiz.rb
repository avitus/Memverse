class ScheduledQuiz

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include IceCube

  sidekiq_options :retry => false # Don't retry quiz if something goes wrong

  recurrence do
    secondly(30)
  end

  def perform

    # ========================================================================
    # Try to find quiz starting in next minute, else return false
    # ========================================================================

    quiz = Quiz.where("start_time > ? and start_time < ?",
                        Time.now, Time.now + 1.minute).first

    return false if quiz.nil?
    return false if quiz.quiz_questions.count == 0
    return false if quiz.id == 1 # This is the Wed/Sat quiz which is started with a different worker

    # ========================================================================
    # Verify that quiz has not been started by another worker
    # ========================================================================

    # Select PubNub channel
    channel = "quiz-#{quiz.id}"

    if (status = $redis.hmget(channel, "status").try(:first)) && !status.nil?
      return false if status.include? "In progress"
    end

    puts "===> Quiz ##{quiz.id} : Grabbed by ScheduledQuiz worker"

    # Save status of quiz in redis
    $redis.hset(channel, "status", "In progress. Chat opening soon.")

    if (sleep_time = quiz.start_time - Time.now) && sleep_time > 0
      puts "===> Quiz ##{quiz.id} : Sleeping #{sleep_time} till chat opens"
      sleep sleep_time
      $redis.hset(channel, "status", "In progress. Chat open. Wait for question.")
    end

    # ========================================================================
    # Announce quiz
    # ========================================================================
    broadcast = "#{quiz.name} is starting. <a href=\"live_quiz/#{quiz.id}\">Join now!</a>"
    Tweet.create(:news => broadcast, :user_id => 1, :importance => 2)  # Admin tweet => user_id = 1

    # ========================================================================
    # Setup quiz, clear old scores
    # ========================================================================
    puts "===> Quiz ##{quiz.id} : Opening quiz room at " + Time.now.to_s

    # TODO: Allow concurrent quizzes

    # Clear participant and question scores from Redis
    participants = $redis.keys("user-*")       # user ID's
    questions    = $redis.keys("qnum-*")       # question numbers
    participants.each { |p| $redis.del(p) }
    questions.each    { |q| $redis.del(q) }

    # Save status of quiz in redis
    $redis.hset(channel, "status", "In progress. Wait for question.")

    # ========================================================================
    # PubNub callback function
    # ========================================================================
    @my_callback = lambda { |envelope|
      if envelope.error
        # If message is not sent we should probably try to send it again
        puts("==== ! Failed to send message ! ==========")
        puts( envelope.inspect )
      end
    }

    # #<Pubnub::Envelope:0x007fdf869c67c0
    #  @channel="quiz-1",
    #  @error=nil,
    #  @error_message=nil,
    #  @first=true,
    #  @history_end=nil,
    #  @history_start=nil,
    #  @last=true,
    #  @message={
    #    :meta=>"question",
    #    :q_id=>615,
    #    :q_num=>24,
    #    :q_type=>"mcq",
    #    :mc_question=>"In Paul's farewell to the Ephesians he says: ... He knew that after he left ______ .",
    #    :mc_option_a=>"There would be conflict within the Ephesian church.",
    #    :mc_option_b=>"The sheep would go astray.",
    #    :mc_option_c=>"Wolves would enter and attack the flock.",
    #    :mc_option_d=>"He would be arrested in Jerusalem.",
    #    :mc_answer=>"C",
    #    :time_alloc=>35},
    #  @object=#<Net::HTTPOK 200 OK readbody=true>,
    #    @payload=nil,
    #    @response="[1,\"Sent\",\"13988747805988965\"]",
    #  @response_message="Sent",
    #  @service=nil,
    #  @status=200,
    #  @timetoken="13988747805988965",
    #  @timetoken_update=nil>

    # ========================================================================
    # Open quiz chat channel 5 minutes prior to start
    # ========================================================================
    puts "===> Quiz ##{quiz.id} : Opening chat at " + Time.now.to_s
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
        :http_sync => true,
        :callback => @my_callback
      )
    end

    Rails.env.production? ? sleep(300) : sleep(30)  # 5 minutes for chatting

    # ========================================================================
    # Main question loop
    # ========================================================================

    puts "===> Quiz ##{quiz.id} : Starting quiz at " + Time.now.to_s

    quiz_questions    = quiz.quiz_questions.order("question_no ASC")

    quiz_questions.each { |q|
      passages   = q.passage_translations
      ref        = q.passage
      num        = q.question_no

      case q.question_type
      when "recitation"
        time_alloc = (q.passage_translations.first.last.split(" ").length * 2.5 + 15.0).to_i # 24 WPM typing speed with 15 seconds to think

        PN.publish(
          :channel  => channel,
          :message  => {
            :meta       => "question",
            :q_num      => num,
            :q_id       => q.id,
            :q_type     => "recitation",
            :q_ref      => ref,
            :q_passages => passages,
            :time_alloc => time_alloc
          },
          :http_sync => true,
          :callback  => @my_callback
        )
        sleep(time_alloc+1)
      when "reference"
        PN.publish(
          :channel  => channel,
          :message  => {
            :meta       => "question",
            :q_num      => num,
            :q_id       => q.id,
            :q_type     => "reference",
            :q_ref      => ref,
            :q_passages => passages,
            :time_alloc => 25
          },
          :http_sync => true,
          :callback => @my_callback
        )
        sleep(26)
      when "mcq"
        PN.publish(
          :channel  => channel,
          :message  => {
            :meta         => "question",
            :q_num        => num,
            :q_id         => q.id,
            :q_type       => "mcq",
            :mc_question  => q.mc_question,
            :mc_option_a  => q.mc_option_a,
            :mc_option_b  => q.mc_option_b,
            :mc_option_c  => q.mc_option_c,
            :mc_option_d  => q.mc_option_d,
            :mc_answer    => q.mc_answer,
            :time_alloc   => 30
          },
          :http_sync => true,
          :callback => @my_callback
        )
        sleep(31)
      else
        sleep(20)
      end

      scoreboard = Array.new

      participants = $redis.keys("user-*")
      participants.each { |p| scoreboard << $redis.hgetall(p) }

      scoreboard = scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

      PN.publish(
        :channel  => channel,
        :message  => {
          :meta => "scoreboard",
          :scoreboard => scoreboard
        },
        :http_sync => true,
        :callback => @my_callback
      )
    } # end of question loop

    # ========================================================================
    # Update quiz status
    # ========================================================================

    $redis.hset(channel, "status", "Finished") # Update quiz status in redis
    puts "===> Quiz ##{quiz.id} : Finished quiz #{quiz.id} at " + Time.now.to_s

    # ========================================================================
    # Update difficulty for all questions
    # ========================================================================
    # quiz_table = Array.new
    # quiz_questions = $redis.keys("qnum-*")
    # quiz_questions.each do |qq|
    #   quiz_table << $redis.hgetall(qq)
    # end

    # puts '----------------------------------------------------------------------------------------'
    # puts '#  |  ID  |  Answers Submitted  |  Total Score'
    # puts '----------------------------------------------------------------------------------------'
    # quiz_table.each_with_index do |qq, index|
    #   q_id           = qq['qq_id'].to_i             # Quiz question ID
    #   q_count        = qq['answered'].to_i          # Number of people who answered this question
    #   q_total        = qq['total_score'].to_i       # Total score, 10 = max
    #   q_perc_correct = q_total.to_f / q_count * 10  # Calculate score as a %

    #   puts index.to_s + "      " + qq['qq_id'] + "         " + qq['answered'] + "                  " + qq['total_score']

    #   # Update quiz question difficulty in database
    #   question = QuizQuestion.find( q_id )
    #   question.update_difficulty( q_count, q_perc_correct )

    # end

    # ========================================================================
    # Record final scoreboard in log file
    # ========================================================================
    final_scoreboard = Array.new
    participants     = $redis.keys("user-*")
    participants.each { |p| final_scoreboard << $redis.hgetall(p) }
    final_scoreboard = final_scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

    puts "===> Quiz ##{quiz.id} : Final Quiz Scores"
    puts "==================="
    final_scoreboard.each do |usr|
      puts "[" + usr['score'] + "] - " + usr['name']
    end

    gold_ribbon_name   = final_scoreboard[0]['name']
    # silver_ribbon_name = final_scoreboard[1]['name']
    # bronze_ribbon_name = final_scoreboard[2]['name']  # Need to check that we have at least 3 participants

    gold_ribbon_id     = final_scoreboard[0]['id']
    # silver_ribbon_id   = final_scoreboard[1]['id']
    # bronze_ribbon_id   = final_scoreboard[2]['id']

    broadcast  = "#{gold_ribbon_name} won #{quiz.name}"
    Tweet.create(:news => broadcast, :user_id => gold_ribbon_id, :importance => 2)

    # ========================================================================
    # Close chat after ten minutes
    # ========================================================================
    puts "===> Quiz ##{quiz.id} : Quiz over. Sleeping for 10 minutes, then shutting down chat."
    Rails.env.production? ? sleep(600) : sleep(30)

    new_status = "Closed"
    $redis.hset("chat-#{channel}", "status", new_status)
    PN.publish( :channel  => channel, :message  => {
        :meta => "chat_status",
        :status => new_status
      },
      :http_sync => true,
      :callback => @my_callback
    )

    puts "===> Quiz ##{quiz.id} : Chat closed and sidetiq job finished."

  end

end
