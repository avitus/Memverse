#-----------------------------------------------------------------------------------------------------------
# This rake task is used for testing the quiz functionality
#-----------------------------------------------------------------------------------------------------------
namespace :quiz do

  desc "Start quiz"
  task :start_test => :environment do

    STDOUT.puts "Quiz ID:"
    quiz_id = STDIN.gets.chomp.to_i

    # ========================================================================
    # Setup quiz, clear old scores
    # ========================================================================
    puts "===> Opening quiz room at " + Time.now.to_s

    # Clear participant and question scores from Redis
    participants = $redis.keys("user-*")       # user ID's
    questions    = $redis.keys("qnum-*")       # question numbers
    participants.each { |p| $redis.del(p) }
    questions.each    { |q| $redis.del(q) }

    # Select quiz and set up PubNub channel
    quiz    = Quiz.find(quiz_id)
    channel = "test-quiz"  # General knowledge quiz will always have ID=1

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

    # ========================================================================
    # Open quiz chat channel prior to start
    # ========================================================================
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
        :http_sync => true,
        :callback => @my_callback
      )
    end

	sleep(10)  # time (seconds) allowed for chatting

    # ========================================================================
    # Main question loop
    # ========================================================================

    q_num_array = Array(1..5)

    puts "===> Starting quiz at " + Time.now.to_s

    q_num_array.each do |q_num|

      puts "===> Question: " + q_num.to_s

      # Pick a question at random
      q = QuizQuestion.mcq.approved.sort_by{ rand }.first
      # q = QuizQuestion.mcq.approved.order(:last_asked).first

      # Update question to show that it was asked today
      # q.update_attribute( :last_asked, Date.today )

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
        :http_sync => true,
        :callback => @my_callback
      )

      # Time to answer question
      sleep( q.time_allocation )

      # Update final
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
        :http_sync => true,
        :callback => @my_callback
      )

    end # of question loop

    # ========================================================================
    # Update quiz status, set start time for next quiz
    # ========================================================================
    $redis.hset(channel, "status", "Finished") # Update quiz status in redis
    puts "===> Finished quiz at " + Time.now.to_s


    # ========================================================================
    # Close chat after ten minutes
    # ========================================================================
    puts "Quiz now over. Sleeping for a while, then shutting down chat."
    sleep(10) # sleep time (in seconds) post quiz

    new_status = "Closed"
    $redis.hset("chat-#{channel}", "status", new_status)
    PN.publish( :channel  => channel, :message  => {
        :meta => "chat_status",
        :status => new_status
      },
      :http_sync => true,
      :callback => @my_callback
    )

    puts "Chat closed - task complete"
  
  end

end

