class KnowledgeQuiz

  include Sidekiq::Worker
  include IceCube
  include PushNotification

  sidekiq_options :retry => false # Don't retry quiz if something goes wrong

  def perform

    # ========================================================================
    # Announce quiz
    # ========================================================================
    broadcast  = "The Bible knowledge quiz is starting. <a href=\"live_quiz\">Join now!</a>"
    Tweet.create(:news => broadcast, :user_id => 1, :importance => 2)  # Admin tweet => user_id = 1
    ios_quiz_alert("The Bible trivia quiz is starting now.")

    # ========================================================================
    # Calculate start time for next quiz
    # ========================================================================
    schedule = IceCube::Schedule.new( Time.now )
    schedule.add_recurrence_rule( IceCube::Rule.weekly.day(:wednesday).hour_of_day(9 ).minute_of_hour(0).second_of_minute(0) )
    schedule.add_recurrence_rule( IceCube::Rule.weekly.day(:saturday ).hour_of_day(15).minute_of_hour(0).second_of_minute(0) )
    next_quiz_time = schedule.next_occurrence

    # ========================================================================
    # Setup quiz, clear old scores
    # ========================================================================
    Sidekiq.logger.info "===> Opening quiz room at " + Time.now.to_s

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

    # ========================================================================
    # PubNub callback function
    # ========================================================================
    @my_callback = lambda { |envelope|
      if envelope.error
        # If message is not sent we should probably try to send it again
        Sidekiq.logger.info("==== ! Failed to send message ! ==========")
        Sidekiq.logger.info( envelope.inspect )
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
    Sidekiq.logger.info "===> Opening chat at " + Time.now.to_s
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
    if Rails.env.production?
      q_num_array = Array(1..25) # Set up number of questions
    else
      q_num_array = Array(1..3)
    end

    Sidekiq.logger.info "===> Starting quiz at " + Time.now.to_s

    q_num_array.each do |q_num|

      Sidekiq.logger.info "===> Question: " + q_num.to_s

      # Pick a question at random
      # q = QuizQuestion.mcq.approved.fresh.sort_by{ rand }.first
      q = QuizQuestion.mcq.approved.order(:last_asked).first

      # Update question to show that it was asked today
      q.update_attribute( :last_asked, Date.today )

      # Publish question
      PN.publish( 
        channel: channel, 
        message: {
          meta:        "question",
          q_id:        q.id,
          q_num:       q_num,
          q_type:      "mcq",
          mc_question: q.mc_question,
          mc_option_a: q.mc_option_a,
          mc_option_b: q.mc_option_b,
          mc_option_c: q.mc_option_c,
          mc_option_d: q.mc_option_d,
          mc_answer:   q.mc_answer,
          time_alloc:  q.time_allocation
        },
        http_sync: true,
        callback:  @my_callback
      )

      # Time to answer question
      sleep( q.time_allocation )

      # Update final
      Sidekiq.logger.info "===> Updating scoreboard"

      scoreboard = Array.new
      participants = $redis.keys("user-*")
      participants.each { |p| scoreboard << $redis.hgetall(p) }
      scoreboard = scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

      # Publish scoreboard
      PN.publish( channel: channel, message: {
          meta: "scoreboard",
          scoreboard: scoreboard
        },
        http_sync: true,
        callback:  @my_callback
      )

    end # of question loop

    # ========================================================================
    # Update quiz status, set start time for next quiz
    # ========================================================================
    $redis.hset("quiz-bible-knowledge", "status", "Finished") # Update quiz status in redis
    Sidekiq.logger.info "===> Finished quiz at " + Time.now.to_s

    quiz.update_attribute(:start_time, next_quiz_time) # Update start time for next quiz
    Sidekiq.logger.info "Next knowledge quiz will start at " + next_quiz_time.to_s

    # ========================================================================
    # Update difficulty for all questions
    # ========================================================================
    quiz_table = Array.new
    quiz_questions = $redis.keys("qnum-*")
    quiz_questions.each do |qq|
      quiz_table << $redis.hgetall(qq)
    end

    Sidekiq.logger.info '----------------------------------------------------------------------------------------'
    Sidekiq.logger.info '#  |  ID  |  Answers Submitted  |  Total Score'
    Sidekiq.logger.info '----------------------------------------------------------------------------------------'
    quiz_table.each_with_index do |qq, index|

      q_id           = qq['qq_id'].to_i             # Quiz question ID
      q_count        = qq['answered'].to_i          # Number of people who answered this question
      q_total        = qq['total_score'].to_i       # Total score, 10 = max
      q_perc_correct = q_total.to_f / q_count * 10  # Calculate score as a %

      Sidekiq.logger.info index.to_s + "      " + qq['qq_id'] + "         " + qq['answered'] + "                  " + qq['total_score']

      # Update quiz question difficulty in database
      question = QuizQuestion.find( q_id )
      question.update_difficulty( q_count, q_perc_correct )

    end

    # ========================================================================
    # Record final scoreboard in log file
    # ========================================================================
    final_scoreboard = Array.new
    participants     = $redis.keys("user-*")
    participants.each { |p| final_scoreboard << $redis.hgetall(p) }
    final_scoreboard = final_scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

    Sidekiq.logger.info "Final Quiz Scores"
    Sidekiq.logger.info "==================="
    final_scoreboard.each do |usr|
      Sidekiq.logger.info "[" + usr['score'] + "] - " + usr['name']
    end

    gold_ribbon_name   = final_scoreboard[0]['name'] unless final_scoreboard.empty?
    # silver_ribbon_name = final_scoreboard[1]['name']
    # bronze_ribbon_name = final_scoreboard[2]['name']  # Need to check that we have at least 3 participants

    gold_ribbon_id     = final_scoreboard[0]['id'] unless final_scoreboard.empty?
    # silver_ribbon_id   = final_scoreboard[1]['id']
    # bronze_ribbon_id   = final_scoreboard[2]['id']

    broadcast  = "#{gold_ribbon_name} won the Bible knowledge quiz"
    Tweet.create(:news => broadcast, :user_id => gold_ribbon_id, :importance => 2)

    # Log event to Treasure Data
    TD.event.post('knowledge_quiz', {:gold_ribbon_name => gold_ribbon_name, :gold_ribbon_id => gold_ribbon_id, :gold_ribbon_score => final_scoreboard[0]['score'],
                                     :participants => final_scoreboard.length }) unless final_scoreboard.empty?

    # ========================================================================
    # Close chat after ten minutes
    # ========================================================================
    Sidekiq.logger.info "Quiz now over. Sleeping for 10 minutes, then shutting down chat."
    Rails.env.production? ? sleep(600) : sleep(30)

    new_status = "Closed"
    $redis.hset("chat-#{channel}", "status", new_status)
    PN.publish( channel: channel, message: {
        meta: "chat_status",
        status: new_status
      },
      http_sync: true,
      callback: @my_callback
    )

    Sidekiq.logger.info "Chat closed and sidekiq job finished."

  end

end
