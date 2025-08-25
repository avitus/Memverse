class Admin::QuizDashboardController < ApplicationController
  layout 'admin'
  before_action :authenticate_admin!
  before_action :set_quiz, only: [:show, :start, :stop, :monitor, :participants]
  
  def index
    @quizzes = Quiz.includes(:user, :quiz_questions)
                   .order(start_time: :desc)
                   .page(params[:page])
    
    # Live quiz status
    @live_quizzes = get_live_quizzes
    
    # Upcoming quizzes
    @upcoming_quizzes = Quiz.where('start_time > ?', Time.current)
                            .where('start_time < ?', 24.hours.from_now)
                            .order(start_time: :asc)
    
    # System health
    @system_health = check_system_health
    
    # Recent errors
    @recent_errors = get_recent_errors
  end
  
  def show
    @quiz_session = QuizSession.new(@quiz.id)
    @participants = @quiz_session.get_participants
    @scoreboard = @quiz_session.get_scoreboard
    @quiz_status = @quiz_session.get_quiz_metadata
    @question_stats = @quiz_session.get_question_stats
  end
  
  def monitor
    @quiz_session = QuizSession.new(@quiz.id)
    
    respond_to do |format|
      format.html
      format.json do
        render json: {
          status: @quiz_session.get_quiz_status,
          participants: @quiz_session.get_participants.count,
          scoreboard: @quiz_session.get_scoreboard.first(10),
          metadata: @quiz_session.get_quiz_metadata,
          health: check_quiz_health(@quiz)
        }
      end
    end
  end
  
  def start
    if @quiz.start_time > Time.current
      # Update start time to now
      @quiz.update!(start_time: Time.current)
    end
    
    # Trigger quiz worker
    if @quiz.id == 1
      KnowledgeQuiz.new.perform
    else
      ScheduledQuiz.new.perform
    end
    
    flash[:success] = "Quiz '#{@quiz.name}' has been started manually"
    redirect_to admin_quiz_dashboard_path(@quiz)
  rescue => e
    flash[:error] = "Failed to start quiz: #{e.message}"
    redirect_to admin_quiz_dashboards_path
  end
  
  def stop
    quiz_session = QuizSession.new(@quiz.id)
    
    # Set quiz status to finished
    quiz_session.set_quiz_status(QuizSession::STATUS_FINISHED, {
      stopped_by: current_user.name_or_login,
      stopped_at: Time.current.iso8601
    })
    
    # Clean up resources
    quiz_session.unlock_quiz
    
    # Notify participants
    notify_quiz_stopped(@quiz)
    
    flash[:success] = "Quiz '#{@quiz.name}' has been stopped"
    redirect_to admin_quiz_dashboard_path(@quiz)
  rescue => e
    flash[:error] = "Failed to stop quiz: #{e.message}"
    redirect_to admin_quiz_dashboard_path(@quiz)
  end
  
  def participants
    @quiz_session = QuizSession.new(@quiz.id)
    @participants = @quiz_session.get_participants
    
    respond_to do |format|
      format.html
      format.csv do
        send_data generate_participants_csv(@participants),
                  filename: "quiz_#{@quiz.id}_participants_#{Date.current}.csv"
      end
      format.json { render json: @participants }
    end
  end
  
  def health_check
    health_status = {
      redis: check_redis_health,
      pubnub: check_pubnub_health,
      sidekiq: check_sidekiq_health,
      database: check_database_health,
      timestamp: Time.current.iso8601
    }
    
    overall_health = health_status.values.all? { |v| v == true || v.is_a?(Hash) }
    
    render json: {
      healthy: overall_health,
      components: health_status
    }, status: overall_health ? :ok : :service_unavailable
  end
  
  def error_logs
    @errors = QuizErrorLog.includes(:quiz)
                          .where('created_at > ?', params[:since] || 24.hours.ago)
                          .order(created_at: :desc)
                          .page(params[:page])
    
    respond_to do |format|
      format.html
      format.json { render json: @errors }
    end
  end
  
  def statistics
    @stats = {
      total_quizzes: Quiz.count,
      quizzes_today: Quiz.where('start_time > ?', Date.current.beginning_of_day).count,
      active_participants: get_active_participants_count,
      average_score: calculate_average_score,
      popular_questions: get_popular_questions,
      completion_rate: calculate_completion_rate,
      peak_times: analyze_peak_times
    }
    
    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end
  
  def schedule
    @scheduled_quizzes = Quiz.where('start_time > ?', Time.current)
                             .order(start_time: :asc)
                             .limit(50)
    
    @recurring_schedule = {
      wednesday: { time: '9:00 AM UTC', quiz_id: 1, name: 'Knowledge Quiz' },
      saturday: { time: '3:00 PM UTC', quiz_id: 1, name: 'Knowledge Quiz' }
    }
  end
  
  def create_quiz
    @quiz = Quiz.new(quiz_params)
    @quiz.user = current_user
    
    if @quiz.save
      flash[:success] = "Quiz '#{@quiz.name}' created successfully"
      redirect_to admin_quiz_dashboard_path(@quiz)
    else
      flash[:error] = "Failed to create quiz: #{@quiz.errors.full_messages.join(', ')}"
      render :new
    end
  end
  
  def bulk_manage
    case params[:action_type]
    when 'cancel'
      cancel_quizzes(params[:quiz_ids])
    when 'reschedule'
      reschedule_quizzes(params[:quiz_ids], params[:new_time])
    when 'duplicate'
      duplicate_quizzes(params[:quiz_ids])
    else
      flash[:error] = 'Unknown action'
    end
    
    redirect_to admin_quiz_dashboards_path
  end
  
  private
  
  def authenticate_admin!
    unless current_user&.admin?
      flash[:error] = 'You must be an admin to access this page'
      redirect_to root_path
    end
  end
  
  def set_quiz
    @quiz = Quiz.find(params[:id])
  end
  
  def quiz_params
    params.require(:quiz).permit(:name, :start_time, :quiz_length, :description)
  end
  
  def get_live_quizzes
    Quiz.joins("LEFT JOIN redis_sessions ON redis_sessions.quiz_id = quizzes.id")
        .where("redis_sessions.status = 'in_progress' OR quizzes.start_time BETWEEN ? AND ?",
               5.minutes.ago, Time.current)
        .distinct
  rescue
    []
  end
  
  def check_system_health
    {
      redis: check_redis_health,
      pubnub: check_pubnub_health,
      sidekiq: check_sidekiq_health,
      database: check_database_health
    }
  end
  
  def check_redis_health
    $redis.ping == 'PONG'
  rescue => e
    { error: e.message }
  end
  
  def check_pubnub_health
    # In production, would check actual PubNub connection
    { status: 'operational', last_checked: Time.current }
  rescue => e
    { error: e.message }
  end
  
  def check_sidekiq_health
    {
      processes: Sidekiq::ProcessSet.new.size,
      busy: Sidekiq::Workers.new.size,
      enqueued: Sidekiq::Queue.new.size,
      retries: Sidekiq::RetrySet.new.size,
      dead: Sidekiq::DeadSet.new.size
    }
  rescue => e
    { error: e.message }
  end
  
  def check_database_health
    ActiveRecord::Base.connection.active?
  rescue => e
    { error: e.message }
  end
  
  def check_quiz_health(quiz)
    quiz_session = QuizSession.new(quiz.id)
    
    {
      locked: quiz_session.quiz_locked?,
      in_progress: quiz_session.quiz_in_progress?,
      participants: quiz_session.get_participants.count,
      redis_keys: count_redis_keys(quiz.id)
    }
  end
  
  def count_redis_keys(quiz_id)
    pattern = "quiz_session:#{quiz_id}:*"
    $redis.keys(pattern).count
  rescue
    0
  end
  
  def get_recent_errors
    # In production, would fetch from error tracking service
    []
  end
  
  def notify_quiz_stopped(quiz)
    # Send PubNub notification
    PN.publish(
      channel: "quiz-#{quiz.id}",
      message: {
        meta: 'quiz_stopped',
        data: {
          message: 'Quiz has been stopped by administrator',
          stopped_by: current_user.name_or_login
        }
      }
    )
  rescue => e
    Rails.logger.error "Failed to notify quiz stop: #{e.message}"
  end
  
  def generate_participants_csv(participants)
    CSV.generate(headers: true) do |csv|
      csv << ['User ID', 'Name', 'Login', 'Score']
      
      participants.each do |participant|
        csv << [
          participant['id'],
          participant['name'],
          participant['login'],
          participant['score']
        ]
      end
    end
  end
  
  def get_active_participants_count
    Quiz.where('start_time > ?', 1.hour.ago)
        .joins(:participants)
        .distinct
        .count('participants.user_id')
  rescue
    0
  end
  
  def calculate_average_score
    # Would calculate from recent quiz sessions
    0
  end
  
  def get_popular_questions
    QuizQuestion.joins(:quiz_question_stats)
                .order('quiz_question_stats.times_used DESC')
                .limit(10)
  rescue
    []
  end
  
  def calculate_completion_rate
    # Percentage of users who complete quizzes they start
    0
  end
  
  def analyze_peak_times
    # Analyze when most users participate in quizzes
    {}
  end
  
  def cancel_quizzes(quiz_ids)
    Quiz.where(id: quiz_ids).update_all(status: 'cancelled')
    flash[:success] = "#{quiz_ids.count} quizzes cancelled"
  end
  
  def reschedule_quizzes(quiz_ids, new_time)
    Quiz.where(id: quiz_ids).update_all(start_time: new_time)
    flash[:success] = "#{quiz_ids.count} quizzes rescheduled"
  end
  
  def duplicate_quizzes(quiz_ids)
    count = 0
    Quiz.where(id: quiz_ids).find_each do |quiz|
      new_quiz = quiz.dup
      new_quiz.name = "#{quiz.name} (Copy)"
      new_quiz.start_time = nil
      count += 1 if new_quiz.save
    end
    flash[:success] = "#{count} quizzes duplicated"
  end
end