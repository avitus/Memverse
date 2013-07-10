namespace :quiz do
  desc "Start quiz"
  task :start => :environment do
  # should be called with "bundle exec rake quiz:start RAILS_ENV=production"
    STDOUT.puts "Quiz ID:"
    quiz_id = STDIN.gets.chomp.to_i

    quiz = Quiz.find(quiz_id)
    @quiz_master = quiz.user

    ### Setup select_channel method to publish messages via Juggernaut
    def select_channel(receiver)
      puts "#{receiver}"
      return "/live_quiz#{receiver}"
    end

    ### Open chat 10 minutes before quiz
    puts "Setting up 'sleep' to open chat 10 minutes before quiz"
    sleep_time = quiz.start_time - (10 * 60) - Time.now
    sleep(sleep_time)

    puts 'Opening chat'
    channel = "quiz-#{quiz_id}"

    if $redis.exists("chat-#{channel}")
      status = $redis.hmget("chat-#{channel}", "status").first
    end

    unless status && status == "Open"
      new_status = "Open"
      $redis.hset("chat-#{channel}", "status", new_status)
      PN.publish(
        :channel  => channel,
        :message  => {
          :meta => "chat_status",
          :status => new_status
        },
        :callback => @my_callback
      )
      # Juggernaut.publish(select_channel(channel), {:status => new_status})
    end

    ### Start quiz on time
    puts "Setting up 'sleep' to start quiz"
    sleep_time = quiz.start_time - Time.now
    puts "Will be sleeping for #{sleep_time}"
    sleep(sleep_time)

    puts "The time has come. Starting quiz."
    @my_callback = lambda { |message| puts(message) } # for PubNub

    # Delete participant scores from redis
    participants = $redis.keys("user-*")
    participants.each { |p|    $redis.del(p) }

    # Save status of quiz in redis
    $redis.hset("quiz-#{quiz.id}", "status", "In progress. Wait for question.")

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
            :meta => "question",
            :q_num => num,
            :q_type => "recitation",
            :q_ref => ref,
            :q_passages => passages,
            :time_alloc => time_alloc
          },
          :callback => @my_callback
        )
        # Juggernaut.publish( select_channel("/quiz_stream"), {:q_num => num, :q_type => "recitation", :q_ref => ref, :q_passages => passages, :time_alloc => time_alloc} )
        sleep(time_alloc+1)
      when "reference"
        PN.publish(
          :channel  => channel,
          :message  => {
            :meta => "question",
            :q_num => num,
            :q_type => "reference",
            :q_ref => ref,
            :q_passages => passages,
            :time_alloc => 25
          },
          :callback => @my_callback
        )
        # Juggernaut.publish( select_channel("/quiz_stream"), {:q_num => num, :q_type => "reference", :q_ref => ref, :q_passages => passages, :time_alloc => 25} )
        sleep(26)
      when "mcq"
        PN.publish(
          :channel  => channel,
          :message  => {
            :meta => "question",
            :q_num => num,
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
        # Juggernaut.publish( select_channel("/quiz_stream"), {:q_num => num, :q_type => "mcq", :mc_question => q.mc_question, :mc_option_a => q.mc_option_a, :mc_option_b => q.mc_option_b, :mc_option_c => q.mc_option_c, :mc_option_d => q.mc_option_d, :mc_answer => q.mc_answer, :time_alloc => 30} )
        sleep(31)
      else
        sleep(20)
      end

      scoreboard = Array.new

      participants = $redis.keys("user-*")
      participants.each { |p|	scoreboard << $redis.hgetall(p) }

      scoreboard = scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }

      PN.publish(
        :channel  => channel,
        :message  => {
          :meta => "scoreboard",
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
      # Juggernaut.publish( select_channel("/scoreboard"), {:scoreboard => scoreboard} )
    }

    # Update quiz status in redis
    $redis.hset("quiz-#{quiz.id}", "status", "Finished")

    ### Close chat 10 minutes after quiz
    puts "Quiz now over. Sleeping for 10 minutes, then shutting down chat."
    sleep(10*60)

    new_status = "Closed"
    $redis.hset("chat-#{channel}", "status", new_status)
    PN.publish(
      :channel  => channel,
      :message  => {
        :meta => "chat_status",
        :status => new_status
      },
      :callback => @my_callback
    )
    # Juggernaut.publish(select_channel(channel), {:status => new_status})

    puts "Chat closed and rake task finished."
  end
end
