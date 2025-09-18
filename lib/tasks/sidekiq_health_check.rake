namespace :sidekiq do
  desc "Check Sidekiq health and ActiveJob configuration"
  task health_check: :environment do
    puts "\n=== Sidekiq Health Check ==="
    puts "Time: #{Time.current}"

    # Check ActiveJob adapter
    adapter = Rails.application.config.active_job.queue_adapter
    puts "\n1. ActiveJob Queue Adapter: #{adapter}"

    if adapter == :async
      puts "   ⚠️  WARNING: Using :async adapter - jobs run in web server process!"
      puts "   This will cause 'queue full' errors under load."
      puts "   Fix: Set config.active_job.queue_adapter = :sidekiq in production.rb"
    elsif adapter == :sidekiq
      puts "   ✅ Correctly configured to use Sidekiq"
    else
      puts "   ❓ Using #{adapter} adapter"
    end

    # Check Redis connection
    puts "\n2. Redis Connection:"
    begin
      redis_info = Sidekiq.redis(&:info)
      puts "   ✅ Connected to Redis"
      puts "   Version: #{redis_info['redis_version']}"
      puts "   Used memory: #{redis_info['used_memory_human']}"
    rescue => e
      puts "   ❌ Redis connection failed: #{e.message}"
    end

    # Check Sidekiq stats
    puts "\n3. Sidekiq Statistics:"
    begin
      stats = Sidekiq::Stats.new
      processes = Sidekiq::ProcessSet.new

      puts "   Processed: #{stats.processed}"
      puts "   Failed: #{stats.failed}"
      puts "   Scheduled: #{stats.scheduled_size}"
      puts "   Retry: #{stats.retry_size}"
      puts "   Dead: #{stats.dead_size}"
      puts "   Processes: #{processes.size}"
      puts "   Workers: #{processes.sum(&:concurrency)}"

      if processes.size == 0
        puts "\n   ⚠️  WARNING: No Sidekiq processes running!"
        puts "   Start Sidekiq with: systemctl start sidekiq-scheduler sidekiq-workers@1"
      end

      # Check for queue latency
      puts "\n4. Queue Latency:"
      Sidekiq::Queue.all.each do |queue|
        latency = queue.latency
        puts "   #{queue.name}: #{latency.round(2)}s"

        if latency > 60
          puts "     ⚠️  WARNING: High latency detected!"
        end
      end

    rescue => e
      puts "   ❌ Could not fetch Sidekiq stats: #{e.message}"
    end

    # Check cron jobs
    puts "\n5. Scheduled Cron Jobs:"
    begin
      jobs = Sidekiq::Cron::Job.all
      if jobs.empty?
        puts "   ⚠️  No cron jobs loaded"
      else
        jobs.each do |job|
          puts "   - #{job.name}: #{job.cron} (#{job.status})"
        end
      end
    rescue => e
      puts "   ℹ️  Sidekiq-cron not available: #{e.message}"
    end

    puts "\n=== End Health Check ===\n"
  end

  desc "Monitor Sidekiq and alert on issues"
  task monitor: :environment do
    # This could be run via cron every 5 minutes
    adapter = Rails.application.config.active_job.queue_adapter

    if adapter != :sidekiq && Rails.env.production?
      # Send alert
      AdminMailer.sidekiq_misconfiguration_alert(adapter).deliver_later
      Rails.logger.error "CRITICAL: ActiveJob not using Sidekiq adapter in production! Using: #{adapter}"
    end

    # Check if Sidekiq is running
    processes = Sidekiq::ProcessSet.new
    if processes.size == 0 && Rails.env.production?
      AdminMailer.sidekiq_not_running_alert.deliver_later
      Rails.logger.error "CRITICAL: No Sidekiq processes running in production!"
    end

    # Check queue latency
    Sidekiq::Queue.all.each do |queue|
      if queue.latency > 300 # 5 minutes
        AdminMailer.high_queue_latency_alert(queue.name, queue.latency).deliver_later
        Rails.logger.error "CRITICAL: High latency in #{queue.name} queue: #{queue.latency}s"
      end
    end
  end
end