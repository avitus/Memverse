# coding: utf-8

require "juggernaut"

class LiveQuizController < ApplicationController
  
  before_filter :authenticate_user!, :only => :live_quiz
 
 
  #-----------------------------------------------------------------------------------------------------------
  # Quiz setup
  #-----------------------------------------------------------------------------------------------------------
  def live_quiz
    if current_user.translation.nil?
      flash[:notice] = "Please choose a translation and then return to the quiz."
      redirect_to update_profile_path
    end

    @quiz = Quiz.find(params[:quiz] || 1 )
    @quiz_master = @quiz.user
    Rails.logger.info("*** Using quiz #{@quiz.name}. The quiz master is #{@quiz.user.name_or_login}.")

    @chat_status = ($redis.exists("chat-channel2") && $redis.hmget("chat-channel2", "status").first == "Open")?"Open":"Closed"

    quiz_questions = @quiz.quiz_questions.order("question_no ASC")
    @num_questions = quiz_questions.length
  end
  
  #-----------------------------------------------------------------------------------------------------------
  # This method will push questions to the live quiz channel
  #-----------------------------------------------------------------------------------------------------------
  def start_quiz
    Rails.logger.info("*** Quiz starting at #{Time.now}")

    # Delete participant scores from redis
    participants = $redis.keys("user-*")
    participants.each { |p|	$redis.del(p) }

    quiz = Quiz.find(params[:quiz] || 1 )
    @quiz_master = quiz.user
    Rails.logger.info("*** Using quiz number #{quiz.name}. The quiz master is #{@quiz_master.name_or_login}.")

    # Save status of quiz in redis
    $redis.hset("quiz-#{quiz.id}", "status", "In progress. Wait for question.")

    quiz_questions	= quiz.quiz_questions.order("question_no ASC")

    spawn_block(:argv => "spawn-quiz-questions") do 
    quiz_questions.each { |q|
      Rails.logger.info("*** Publishing question #{q.question_no}.")
      Rails.logger.info("*** Question type is: #{q.question_type}.")

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

      scoreboard = publish_scoreboard
      Rails.logger.info("*** Publishing scoreboard after question: #{q.question_no}.")
      Juggernaut.publish( select_channel("/scoreboard"), {:scoreboard => scoreboard} ) 
    }
    end

    # Update quiz status in redis
    $redis.hset("quiz-#{quiz.id}", "status", "Finished")

    respond_to do |format|
      format.all { render :nothing => true, :status => 200 }
    end
  end

  #-----------------------------------------------------------------------------------------------------------
  # Parse questions for quiz presentation
  #-----------------------------------------------------------------------------------------------------------
  def parse_quiz_question(num, type, passage)
    return "#{num}: #{passage} (#{type.capitalize})"
  end

  #-----------------------------------------------------------------------------------------------------------
  # Select channel
  #-----------------------------------------------------------------------------------------------------------
  def select_channel(receiver)
    puts "#{receiver}"
    return "/live_quiz#{receiver}"
  end
  
  #-----------------------------------------------------------------------------------------------------------
  # This method receive scores for each participant
  #-----------------------------------------------------------------------------------------------------------  
  def record_score
    usr_id    = "user-" + params[:usr_id].to_s
    usr_name  = params[:usr_name]
    usr_login = params[:usr_login]
    score     = params[:score]
    
    if score != "false"
      # Store the score in Redis store
      $redis.hincrby(usr_id, 'score', score)
      $redis.hmset(usr_id, 'name', usr_name, 'login', usr_login)
    else
      Rails.logger.info("*** Score was submitted as false for #{usr_name}")
    end

    respond_to do |format|
      format.all { render :nothing => true, :status => 200 }
    end

  end

  #-----------------------------------------------------------------------------------------------------------
  # This method publishes the scoreboard 
  # Format: [{"score"=>"11", "name"=>"Andy"}, {"score"=>"14", "name"=>"Alex"} ]
  #-----------------------------------------------------------------------------------------------------------    
  def publish_scoreboard
  	scoreboard = Array.new
  	
    participants = $redis.keys("user-*")
    participants.each { |p|	scoreboard << $redis.hgetall(p) }

    return scoreboard.sort { |x, y| y['score'].to_i <=> x['score'].to_i }
  end
  
  #-----------------------------------------------------------------------------------------------------------
  # Return the roster via JSON; used for initial roster loading
  #-----------------------------------------------------------------------------------------------------------    
  def roster
  	@roster = Roster.all
	render :json => @roster
  end
  
  #-----------------------------------------------------------------------------------------------------------
  # Return time till quiz starts
  #-----------------------------------------------------------------------------------------------------------    
  def till_start
    @quiz = Quiz.find(params[:id])
    @till = @quiz.start_time - Time.now # time till in seconds

    if @till >= 0
	  hours = (@till/3600).to_i
	  minutes = (@till/60 - hours * 60).to_i
	  seconds = (@till - (minutes * 60 + hours * 3600)).to_i

      render :json => {:time => "+#{hours}h +#{minutes}m +#{seconds}s"}
    elsif $redis.exists("quiz-#{@quiz.id}") && status = $redis.hmget("quiz-#{@quiz.id}", "status")
      render :json => {:status => status}
    else
      render :json => {:status => "Finished"}
    end
  end
end


