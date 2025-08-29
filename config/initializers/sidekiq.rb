# Shared Redis configuration for both client and server
redis_config = {
  url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'),
  pool_timeout: 5,  # Increased from 1 to 5 seconds
  size: ENV.fetch('SIDEKIQ_REDIS_POOL_SIZE', 30).to_i,
  # Redis timeout settings (compatible with redis-client gem)
  timeout: 5,
  read_timeout: 5,   # Add explicit read timeout to prevent ReadTimeoutError
  write_timeout: 5,  # Add explicit write timeout
  connect_timeout: 2 # Add connection timeout
}

# Configure Sidekiq client (for enqueueing jobs)
Sidekiq.configure_client do |config|
  config.redis = redis_config.merge(size: 5) # Smaller pool for clients
  
  # Client-side middleware
  config.client_middleware do |chain|
    # Add job uniqueness middleware to prevent duplicate jobs
    # chain.add SidekiqUniqueJobs::Middleware::Client if defined?(SidekiqUniqueJobs)
  end
end

# Configure Sidekiq server (for processing jobs)
Sidekiq.configure_server do |config|
  config.redis = redis_config
  
  # ========================================================================
  # Configure Logging to File
  # ========================================================================
  require 'logger'
  log_file = Rails.root.join('log', 'sidekiq.log')
  file_logger = Logger.new(log_file)
  file_logger.level = Logger::INFO
  
  if Rails.env.production?
    # Use structured logging in production
    file_logger.formatter = proc do |severity, datetime, progname, msg|
      {
        timestamp: datetime.iso8601,
        level: severity,
        progname: progname,
        message: msg,
        pid: Process.pid,
        thread: Thread.current.object_id
      }.to_json + "\n"
    end
  else
    # Human-readable logging in development
    file_logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
  end
  
  # Set Sidekiq's logger through the config object
  config.logger = file_logger
  
  # In development, also log to stdout for easier debugging
  if Rails.env.development?
    # Create stdout logger with same formatter
    stdout_logger = Logger.new(STDOUT)
    stdout_logger.level = Logger::INFO
    stdout_logger.formatter = file_logger.formatter
    
    # Create a broadcasting logger that writes to both
    require 'active_support/logger'
    broadcast_logger = ActiveSupport::BroadcastLogger.new(file_logger, stdout_logger)
    config.logger = broadcast_logger
  end
  
  # ========================================================================
  # Error Handlers for Monitoring and Alerting
  # ========================================================================
  config.error_handlers << proc do |exception, context_hash|
    Rails.logger.error "Sidekiq job error: #{exception.class} - #{exception.message}"
    Rails.logger.error "Context: #{context_hash}"
    Rails.logger.error exception.backtrace.join("\n") if exception.backtrace
    
    # In production, you might want to send alerts to monitoring services
    if Rails.env.production?
      # Example: Send to error monitoring service
      # Sentry.capture_exception(exception, extra: context_hash) if defined?(Sentry)
      
      # Example: Send critical alerts for specific job types
      if context_hash[:job] && ['KnowledgeQuiz', 'SendReminders'].include?(context_hash[:job]['class'])
        Rails.logger.fatal "CRITICAL: #{context_hash[:job]['class']} failed - immediate attention required"
        # Send urgent alert to admin team
      end
    end
  end
  
  # ========================================================================
  # Server-side Middleware for Job Lifecycle Management
  # ========================================================================
  # Note: In Sidekiq 7.x, logging middleware is included by default
  # and Sidekiq::Middleware::Server::Logging no longer exists
  config.server_middleware do |chain|
    # Add uniqueness middleware for server if available
    # chain.add SidekiqUniqueJobs::Middleware::Server if defined?(SidekiqUniqueJobs)
  end
  
  # ========================================================================
  # Custom Middleware for Performance Monitoring
  # ========================================================================
  config.server_middleware do |chain|
    chain.add(Class.new do
      def call(worker, job, queue)
        start_time = Time.current
        
        begin
          yield
        ensure
          duration = Time.current - start_time
          
          # Different thresholds for different job types
          slow_job_threshold = case job['class']
          when 'ScheduledQuiz', 'KnowledgeQuiz'
            600  # 10 minutes for quiz jobs
          when 'SendReminders'
            120  # 2 minutes for reminder jobs
          when 'UpdateMetrics', 'UpdateSubsections', 'UpdateVerseDifficulty'
            300  # 5 minutes for bulk data processing jobs
          when 'RefreshTagCloud', 'SubsectionPassages'
            60   # 1 minute for medium processing jobs
          else
            30   # 30 seconds for everything else
          end

          if duration > slow_job_threshold
            Rails.logger.warn "SLOW JOB: #{job['class']} took #{duration.round(2)}s (Queue: #{queue})"
          end
          
          # Track job metrics
          job_class = job['class']
          Rails.cache.increment("sidekiq:jobs:#{job_class}:total", 1, expires_in: 1.day)
          Rails.cache.write("sidekiq:jobs:#{job_class}:last_duration", duration.round(2), expires_in: 1.day)
          
          # Track queue depth for monitoring
          Rails.cache.write("sidekiq:queue:#{queue}:last_processed", Time.current, expires_in: 1.hour)
        end
      end
    end)
  end
  
  # ========================================================================
  # Load Cron Schedule (Enhanced with better error handling)
  # ========================================================================
  schedule_file = "config/sidekiq_schedule.yml"
  
  if File.exist?(schedule_file) && Sidekiq.server?
    begin
      schedule = YAML.load_file(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(schedule)
      Rails.logger.info "Loaded #{schedule.keys.size} scheduled jobs from #{schedule_file}"
    rescue => e
      Rails.logger.error "Failed to load Sidekiq schedule: #{e.message}"
      raise e if Rails.env.production? # Fail fast in production
    end
  end
  
  # ========================================================================
  # Dead Job Cleanup (Runs at server startup)
  # ========================================================================
  begin
    require 'sidekiq/api'
    dead_set = Sidekiq::DeadSet.new
    if dead_set.size > 1000
      Rails.logger.warn "Large number of dead jobs detected (#{dead_set.size}). Consider investigating."
    end
  rescue => e
    Rails.logger.warn "Could not check dead set: #{e.message}"
  end
  
  # ========================================================================
  # Health Check Setup
  # ========================================================================
  # Store server startup time for health monitoring
  Rails.cache.write('sidekiq:server:last_startup', Time.current, expires_in: 1.week)
  Rails.cache.write('sidekiq:server:status', 'healthy', expires_in: 1.hour)
  
  # Note: config.periodic was removed in Sidekiq 7.x
  # Health checks should be implemented using a scheduled job or external monitoring
end

# ========================================================================
# Global Sidekiq Configuration
# ========================================================================

# Set default options for jobs
# Note: In Sidekiq 7.x, use default_job_options= method
Sidekiq.default_job_options = { 
  'queue' => 'default', 
  'retry' => 3, 
  'backtrace' => true
}

# Note: Job timeout is not a standard Sidekiq option
# Timeouts should be handled within the job itself or using job_options in the worker class

# ========================================================================
# Custom Logging Configuration
# ========================================================================
# Note: Logging is configured inside the configure_server block above
# This ensures Sidekiq's logger is properly initialized before we modify it