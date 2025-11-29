class Admin::QuizHealthController < ApplicationController
  before_action :authenticate_admin!

  def status
    @quiz_status = {
      redis_status: check_redis_status,
      last_run: check_last_run,
      next_scheduled: check_next_scheduled,
      sidekiq_jobs: check_sidekiq_jobs,
      recent_errors: check_recent_errors,
      current_participants: check_current_participants
    }

    respond_to do |format|
      format.html # Will render app/views/admin/quiz_health/status.html.erb
      format.json { render json: @quiz_status }
    end
  end

  private

  def authenticate_admin!
    redirect_to root_path unless current_user&.admin?
  end

  def check_redis_status
    quiz_data = $redis.hgetall("quiz-bible-knowledge")
    {
      status: quiz_data["status"] || "Not Set",
      current_question: quiz_data["current_q"]&.to_i || 0,
      last_updated: quiz_data["updated_at"],
      raw_data: quiz_data
    }
  rescue => e
    { error: e.message }
  end

  def check_last_run
    last_quiz = Tweet.where(importance: 2)
                     .where("news LIKE ?", "%Bible knowledge quiz%")
                     .order(created_at: :desc)
                     .first

    if last_quiz
      {
        tweet_id: last_quiz.id,
        created_at: last_quiz.created_at,
        time_ago: time_ago_in_words(last_quiz.created_at) + " ago",
        news: last_quiz.news
      }
    else
      { message: "No quiz run found in tweets" }
    end
  end

  def check_next_scheduled
    next_quiz_time = Quiz.next_knowledge_quiz_time

    if next_quiz_time
      {
        time: next_quiz_time,
        time_string: next_quiz_time.strftime("%B %d at %I:%M %p %Z"),
        countdown: distance_of_time_in_words(Time.current, next_quiz_time),
        is_overdue: next_quiz_time < Time.current
      }
    else
      { error: "Could not calculate next quiz time" }
    end
  end

  def check_sidekiq_jobs
    require 'sidekiq-cron'

    jobs = Sidekiq::Cron::Job.all.select { |j| j.name.downcase.include?("quiz") }

    jobs.map do |job|
      {
        name: job.name,
        cron: job.cron,
        last_enqueue: job.last_enqueue_time,
        next_enqueue: job.next_time.to_local_time,
        status: job.status,
        enabled: job.enabled?,
        klass: job.klass
      }
    end
  rescue => e
    [{ error: "Failed to load Sidekiq jobs: #{e.message}" }]
  end

  def check_recent_errors
    # Check for recent quiz-related errors in Redis
    errors = []

    # Check for quiz lock issues
    quiz_lock = $redis.get("quiz_lock:knowledge_quiz")
    if quiz_lock
      errors << {
        type: "Stale Lock",
        message: "Quiz lock is currently held",
        details: quiz_lock,
        suggestion: "If quiz is not running, clear the lock"
      }
    end

    # Check if quiz status indicates an error
    quiz_status = $redis.hget("quiz-bible-knowledge", "status")
    if quiz_status == "Error"
      errors << {
        type: "Quiz Error Status",
        message: "Quiz is in error state",
        suggestion: "Check worker logs for details"
      }
    end

    errors
  end

  def check_current_participants
    # Get participant count from Redis
    participants = $redis.smembers("quiz_participants")
    {
      count: participants.size,
      participant_ids: participants.take(10) # Show first 10
    }
  rescue => e
    { error: e.message }
  end
end