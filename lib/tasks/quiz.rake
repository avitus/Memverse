namespace :quiz do
  desc "Start quiz"
  task :start => :environment do
  # should be called with "bundle exec rake quiz:start quiz_id=ID_HERE RAILS_ENV=production"
    puts "Starting quiz"
	
    # Delete participant scores from redis
    participants = $redis.keys("user-*")
    participants.each { |p|    $redis.del(p) }

    quiz = Quiz.find(ENV['quiz_id'])
    @quiz_master = quiz.user

    # Save status of quiz in redis
    $redis.hset("quiz-#{quiz.id}", "status", "In progress. Wait for question.")

    def select_channel(receiver)
      puts "#{receiver}"
      return "/live_quiz#{receiver}"
    end
	
	quiz_questions    = quiz.quiz_questions.order("question_no ASC")

    quiz_questions.each { |q|
      passages   = q.passage_translations
      ref        = q.passage
      num        = q.question_no

      case q.question_type
      when "recitation"
        time_alloc = (q.passage_translations.first.last.split(" ").length * 2.5 + 15.0).to_i # 24 WPM typing speed with 15 seconds to think
        Juggernaut.publish( select_channel("/quiz_stream"), {:q_num => num, :q_type => "recitation", :q_ref => ref, :q_passages => passages, :time_alloc => time_alloc} )
        sleep(time_alloc+1)                
      when "reference"
        Juggernaut.publish( select_channel("/quiz_stream"), {:q_num => num, :q_type => "reference", :q_ref => ref, :q_passages => passages, :time_alloc => 25} )
        sleep(26)
      when "mcq"
        Juggernaut.publish( select_channel("/quiz_stream"), {:q_num => num, :q_type => "mcq", :mc_question => q.mc_question, :mc_option_a => q.mc_option_a, :mc_option_b => q.mc_option_b, :mc_option_c => q.mc_option_c, :mc_option_d => q.mc_option_d, :mc_answer => q.mc_answer, :time_alloc => 20} )
        sleep(21)
      else
        sleep(20)
      end

      scoreboard = Array.new
  	
      participants = $redis.keys("user-*")
      participants.each { |p|	scoreboard << $redis.hgetall(p) }

      scoreboard = scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }
      Juggernaut.publish( select_channel("/scoreboard"), {:scoreboard => scoreboard} ) 
    }
    
    # Update quiz status in redis
    $redis.hset("quiz-#{quiz.id}", "status", "Finished")
    
  end
end
