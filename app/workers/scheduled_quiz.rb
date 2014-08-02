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

    # ========================================================================
    # Verify that quiz has not been started by another worker
    # ========================================================================

    # Select PubNub channel
    channel = quiz.channel

    if quiz.status
      return false if quiz.status.include? "In progress"
    end

    puts "===> Quiz ##{quiz.id} : Grabbed by ScheduledQuiz worker"

    # Save status of quiz in redis
    quiz.status = "In progress. Chat opening soon."

    if (sleep_time = quiz.start_time - Time.now) && sleep_time > 0
      puts "===> Quiz ##{quiz.id} : Sleeping #{sleep_time} till chat opens"
      sleep sleep_time
      quiz.status = "In progress. Chat open. Wait for question."
    end

    # ========================================================================
    # Announce quiz
    # ========================================================================
    quiz.announce

    # ========================================================================
    # Setup quiz, clear old scores
    # ========================================================================
    puts "===> Quiz ##{quiz.id} : Opening quiz room at " + Time.now.to_s

    # Clear participant and question scores from Redis
    quiz.redis_clear_data

    # Save status of quiz in redis
    quiz.status = "In progress. Wait for question."

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
    #  @channel="quiz1",
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

    chat_channel = ChatChannel.find(channel)
    chat_channel.status = "Open"

    Rails.env.production? ? sleep(300) : sleep(30)  # 5 minutes for chatting

    # ========================================================================
    # Main question loop
    # ========================================================================

    puts "===> Quiz ##{quiz.id} : Starting quiz at " + Time.now.to_s

    quiz_questions    = quiz.quiz_questions.order("question_no ASC")

    quiz_questions.each { |q|
      q.push_to_channel
      sleep(q.time_alloc + 1)

      quiz.publish_scoreboard
    } # end of question loop

    # ========================================================================
    # Update quiz status
    # ========================================================================

    quiz.status = "Finished"
    puts "===> Quiz ##{quiz.id} : Finished quiz #{quiz.id} at " + Time.now.to_s

    # ========================================================================
    # Update difficulty for all questions
    # ========================================================================
    # quiz_table = Array.new
    # quiz.redis_questions.each do |qq|
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
    quiz.redis_participants.each { |p| final_scoreboard << $redis.hgetall(p) }
    final_scoreboard.map {|x| x.merge(score: x[:score].to_i) }
    final_scoreboard = final_scoreboard.sort { |x, y| y[:score] <=> x[:score] }

    puts "===> Quiz ##{quiz.id} : Final Quiz Scores"
    puts "==================="
    final_scoreboard.each do |usr|
      puts "[" + usr['score'] + "] - " + usr['name']
    end

    top_score = final_scoreboard[0][:score]

    gold_ribbon = Array.new

    for user in final_scoreboard
      break if user[:score] != top_score
      gold_ribbon << User.find(user[:id])
    end

    # Need to check that we have at least 3 participants
    # silver_ribbon   = final_scoreboard[1]['id']
    # bronze_ribbon   = final_scoreboard[2]['id']

    Tweet.create(
      news: "#{gold_ribbon.to_sentence} won #{quiz.name}",
      user: gold_ribbon[0],
      importance: 2
    )

    # ========================================================================
    # Close chat after ten minutes
    # ========================================================================
    puts "===> Quiz ##{quiz.id} : Quiz over. Sleeping for 10 minutes, then shutting down chat."
    Rails.env.production? ? sleep(600) : sleep(30)

    chat_channel.status = "Closed"

    puts "===> Quiz ##{quiz.id} : Chat closed and sidetiq job finished."

  end

end
