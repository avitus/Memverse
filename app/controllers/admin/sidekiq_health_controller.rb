# frozen_string_literal: true

# Admin controller for monitoring Sidekiq health and performance
# Provides endpoints for queue monitoring, job metrics, and system health checks
class Admin::SidekiqHealthController < ApplicationController
  # Ensure only admin users can access these endpoints
  before_action :authenticate_admin!
  
  # Skip CSRF verification for API-style endpoints
  skip_before_action :verify_authenticity_token, only: [:health_check, :metrics]
  
  # ========================================================================
  # Health Check Endpoint - Returns JSON health status
  # ========================================================================
  def health_check
    health_data = {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      checks: {}
    }
    
    begin
      # Check Redis connectivity
      health_data[:checks][:redis] = check_redis_connectivity
      
      # Check queue depths
      health_data[:checks][:queues] = check_queue_depths
      
      # Check failed jobs
      health_data[:checks][:failed_jobs] = check_failed_jobs
      
      # Check scheduled jobs
      health_data[:checks][:scheduled_jobs] = check_scheduled_jobs
      
      # Check server heartbeat
      health_data[:checks][:server_heartbeat] = check_server_heartbeat
      
      # Check job processing times
      health_data[:checks][:processing_times] = check_processing_times
      
      # Overall health determination
      health_data[:status] = determine_overall_health(health_data[:checks])
      
    rescue => e
      health_data[:status] = 'error'
      health_data[:error] = e.message
      Rails.logger.error "Sidekiq health check error: #{e.message}"
    end
    
    # Set HTTP status based on health
    status_code = health_data[:status] == 'healthy' ? 200 : 503
    
    render json: health_data, status: status_code
  end
  
  # ========================================================================
  # Metrics Endpoint - Returns detailed performance metrics
  # ========================================================================
  def metrics
    metrics_data = {
      timestamp: Time.current.iso8601,
      server: server_metrics,
      queues: queue_metrics,
      jobs: job_metrics,
      redis: redis_metrics
    }
    
    render json: metrics_data
  end
  
  # ========================================================================
  # Dashboard - HTML interface for monitoring
  # ========================================================================
  def dashboard
    @stats = Sidekiq::Stats.new
    @queues = queue_details
    @scheduled_jobs = scheduled_job_details
    @recent_failures = recent_job_failures
    @job_metrics = job_performance_metrics
  end
  
  # ========================================================================
  # Queue Management Actions
  # ========================================================================
  
  # Clear all failed jobs
  def clear_failed_jobs
    cleared_count = Sidekiq::RetrySet.new.clear + Sidekiq::DeadSet.new.clear
    
    flash[:notice] = "Cleared #{cleared_count} failed jobs"
    redirect_to admin_sidekiq_health_dashboard_path
  end
  
  # Retry all failed jobs
  def retry_failed_jobs
    retry_count = 0
    
    Sidekiq::RetrySet.new.each(&:retry)
    Sidekiq::DeadSet.new.each { |job| job.retry; retry_count += 1 }
    
    flash[:notice] = "Retrying #{retry_count} failed jobs"
    redirect_to admin_sidekiq_health_dashboard_path
  end
  
  # Pause/Resume queue processing
  def toggle_queue
    queue_name = params[:queue_name]
    action = params[:action_type] # 'pause' or 'resume'
    
    if action == 'pause'
      Sidekiq::Queue.new(queue_name).pause
      flash[:notice] = "Paused queue: #{queue_name}"
    elsif action == 'resume'
      Sidekiq::Queue.new(queue_name).unpause
      flash[:notice] = "Resumed queue: #{queue_name}"
    end
    
    redirect_to admin_sidekiq_health_dashboard_path
  end
  
  private
  
  # ========================================================================
  # Authentication
  # ========================================================================
  
  def authenticate_admin!
    # Implement your admin authentication logic here
    # Example implementations:
    
    # Option 1: Check if current user is admin
    unless current_user&.admin?
      render json: { error: 'Unauthorized' }, status: 401
      return
    end
    
    # Option 2: Use HTTP Basic Auth in production
    # if Rails.env.production?
    #   authenticate_or_request_with_http_basic do |username, password|
    #     username == ENV['SIDEKIQ_ADMIN_USER'] && password == ENV['SIDEKIQ_ADMIN_PASSWORD']
    #   end
    # end
    
    # Option 3: IP whitelist for monitoring systems
    # allowed_ips = ENV['SIDEKIQ_MONITOR_IPS']&.split(',') || []
    # unless allowed_ips.include?(request.remote_ip)
    #   render json: { error: 'Access denied' }, status: 403
    #   return
    # end
  end
  
  # ========================================================================
  # Health Check Methods
  # ========================================================================
  
  def check_redis_connectivity
    start_time = Time.current
    
    # Test Redis connection with a simple operation
    Sidekiq.redis { |conn| conn.ping }
    
    response_time = Time.current - start_time
    
    {
      status: 'healthy',
      response_time_ms: (response_time * 1000).round(2),
      connection_pool_size: Sidekiq.redis_pool.size,
      available_connections: Sidekiq.redis_pool.available
    }
  rescue => e
    {
      status: 'error',
      error: e.message
    }
  end
  
  def check_queue_depths
    stats = Sidekiq::Stats.new
    queue_data = {}
    
    %w[critical high default low].each do |queue_name|
      queue = Sidekiq::Queue.new(queue_name)
      depth = queue.size
      
      # Define thresholds based on queue type
      threshold = case queue_name
                  when 'critical' then 5
                  when 'high' then 25
                  when 'default' then 100
                  when 'low' then 500
                  else 100
                  end
      
      status = depth > threshold ? 'warning' : 'healthy'
      
      queue_data[queue_name] = {
        depth: depth,
        threshold: threshold,
        status: status,
        paused: queue.paused?
      }
    end
    
    queue_data
  end
  
  def check_failed_jobs
    retry_set = Sidekiq::RetrySet.new
    dead_set = Sidekiq::DeadSet.new
    
    retry_count = retry_set.size
    dead_count = dead_set.size
    
    # Define failure thresholds
    status = case
             when dead_count > 100 then 'critical'
             when retry_count > 50 then 'warning'
             else 'healthy'
             end
    
    {
      status: status,
      retry_count: retry_count,
      dead_count: dead_count,
      recent_failures: recent_job_failures(limit: 5)
    }
  end
  
  def check_scheduled_jobs
    scheduled_set = Sidekiq::ScheduledSet.new
    cron_jobs = Sidekiq::Cron::Job.all
    
    {
      status: 'healthy',
      scheduled_count: scheduled_set.size,
      cron_jobs_count: cron_jobs.size,
      next_job: scheduled_set.first&.at,
      cron_jobs_enabled: cron_jobs.count(&:enabled?)
    }
  end
  
  def check_server_heartbeat
    last_heartbeat = Rails.cache.read('sidekiq:server:last_heartbeat')
    server_startup = Rails.cache.read('sidekiq:server:last_startup')
    
    if last_heartbeat.nil?
      return { status: 'unknown', message: 'No heartbeat data available' }
    end
    
    time_since_heartbeat = Time.current - last_heartbeat
    
    status = case
             when time_since_heartbeat > 300 then 'critical' # 5 minutes
             when time_since_heartbeat > 120 then 'warning'  # 2 minutes
             else 'healthy'
             end
    
    {
      status: status,
      last_heartbeat: last_heartbeat.iso8601,
      seconds_since_heartbeat: time_since_heartbeat.round(1),
      server_uptime_seconds: server_startup ? (Time.current - server_startup).round(1) : nil
    }
  end
  
  def check_processing_times
    critical_jobs = %w[KnowledgeQuiz SendReminders]
    job_times = {}
    overall_status = 'healthy'
    
    critical_jobs.each do |job_class|
      last_duration = Rails.cache.read("sidekiq:jobs:#{job_class}:last_duration")
      total_count = Rails.cache.read("sidekiq:jobs:#{job_class}:total") || 0
      
      if last_duration
        # Define performance thresholds (in seconds)
        threshold = job_class == 'KnowledgeQuiz' ? 1800 : 300 # 30 min for quiz, 5 min for others
        
        status = last_duration > threshold ? 'warning' : 'healthy'
        overall_status = 'warning' if status == 'warning'
        
        job_times[job_class] = {
          last_duration_seconds: last_duration,
          threshold_seconds: threshold,
          total_executions_today: total_count,
          status: status
        }
      end
    end
    
    {
      status: overall_status,
      jobs: job_times
    }
  end
  
  def determine_overall_health(checks)
    statuses = checks.values.map { |check| check.is_a?(Hash) ? check[:status] : check.values.map { |v| v[:status] } }.flatten
    
    return 'critical' if statuses.include?('critical')
    return 'warning' if statuses.include?('warning')
    return 'error' if statuses.include?('error')
    
    'healthy'
  end
  
  # ========================================================================
  # Metrics Collection Methods
  # ========================================================================
  
  def server_metrics
    stats = Sidekiq::Stats.new
    
    {
      processed: stats.processed,
      failed: stats.failed,
      busy: stats.workers_size,
      enqueued: stats.enqueued,
      scheduled: stats.scheduled_size,
      retries: stats.retry_size,
      dead: stats.dead_size,
      default_latency: stats.default_queue_latency
    }
  end
  
  def queue_metrics
    metrics = {}
    
    Sidekiq::Queue.all.each do |queue|
      metrics[queue.name] = {
        size: queue.size,
        latency: queue.latency,
        paused: queue.paused?
      }
    end
    
    metrics
  end
  
  def job_metrics
    metrics = {}
    
    # Get job class performance from cache
    %w[KnowledgeQuiz ScheduledQuiz SendReminders UpdateMetrics ForumReviewNotifier].each do |job_class|
      total = Rails.cache.read("sidekiq:jobs:#{job_class}:total") || 0
      last_duration = Rails.cache.read("sidekiq:jobs:#{job_class}:last_duration")
      
      metrics[job_class] = {
        total_executions_today: total,
        last_duration_seconds: last_duration
      }
    end
    
    metrics
  end
  
  def redis_metrics
    info = nil
    memory_usage = nil
    
    Sidekiq.redis do |conn|
      info = conn.info
      memory_usage = info['used_memory_human']
    end
    
    {
      memory_usage: memory_usage,
      connected_clients: info['connected_clients'],
      total_commands_processed: info['total_commands_processed'],
      uptime_seconds: info['uptime_in_seconds']
    }
  rescue => e
    { error: e.message }
  end
  
  # ========================================================================
  # Dashboard Helper Methods
  # ========================================================================
  
  def queue_details
    details = {}
    
    Sidekiq::Queue.all.each do |queue|
      details[queue.name] = {
        size: queue.size,
        latency: queue.latency.round(2),
        paused: queue.paused?,
        jobs: queue.first(5).map do |job|
          {
            class: job.klass,
            args: job.args.first(3), # Limit args for display
            created_at: Time.at(job.created_at),
            retries: job['retry_count'] || 0
          }
        end
      }
    end
    
    details
  end
  
  def scheduled_job_details
    Sidekiq::Cron::Job.all.map do |job|
      {
        name: job.name,
        class: job.klass,
        cron: job.cron,
        enabled: job.enabled?,
        last_run: job.last_enqueue_time,
        next_run: job.should_enqueue?(Time.now)
      }
    end
  end
  
  def recent_job_failures(limit: 10)
    failures = []
    
    # Get recent failures from retry set
    Sidekiq::RetrySet.new.each(limit: limit) do |job|
      failures << {
        class: job.klass,
        queue: job.queue,
        args: job.args.first(2), # Limit args for display
        error_class: job['error_class'],
        error_message: job['error_message'],
        failed_at: Time.at(job['failed_at']),
        retries: job['retry_count']
      }
    end
    
    # Get recent failures from dead set
    Sidekiq::DeadSet.new.each(limit: limit - failures.size) do |job|
      failures << {
        class: job.klass,
        queue: job.queue,
        args: job.args.first(2),
        error_class: job['error_class'],
        error_message: job['error_message'],
        failed_at: Time.at(job['failed_at']),
        retries: job['retry_count'],
        dead: true
      }
    end
    
    failures
  end
  
  def job_performance_metrics
    metrics = {}
    
    %w[KnowledgeQuiz ScheduledQuiz SendReminders UpdateMetrics].each do |job_class|
      total = Rails.cache.read("sidekiq:jobs:#{job_class}:total") || 0
      last_duration = Rails.cache.read("sidekiq:jobs:#{job_class}:last_duration")
      
      metrics[job_class] = {
        executions_today: total,
        last_duration: last_duration ? "#{last_duration}s" : 'N/A',
        avg_duration: last_duration ? "#{last_duration}s" : 'N/A' # Could be enhanced with better tracking
      }
    end
    
    metrics
  end
end