#!/usr/bin/env ruby
# Diagnostic script to check Sidekiq health in production
# Run this in production Rails console: bundle exec rails console

puts "\n===== SIDEKIQ PRODUCTION DIAGNOSTIC CHECK ====="
puts "Date: #{Time.now}"
puts "=" * 50

# 1. Check Redis Connection
puts "\n1. REDIS CONNECTION:"
begin
  redis_info = Sidekiq.redis { |conn| conn.info }
  puts "   ✓ Redis is connected"
  puts "   - Version: #{redis_info['redis_version']}"
  puts "   - Connected clients: #{redis_info['connected_clients']}"
  puts "   - Used memory: #{redis_info['used_memory_human']}"
rescue => e
  puts "   ✗ Redis connection failed: #{e.message}"
end

# 2. Check Sidekiq Stats
puts "\n2. SIDEKIQ STATS:"
begin
  stats = Sidekiq::Stats.new
  puts "   - Processed jobs: #{stats.processed}"
  puts "   - Failed jobs: #{stats.failed}"
  puts "   - Scheduled jobs: #{stats.scheduled_size}"
  puts "   - Retry queue size: #{stats.retry_size}"
  puts "   - Dead jobs: #{stats.dead_size}"
  puts "   - Enqueued jobs: #{stats.enqueued}"
  
  # Check each queue
  puts "\n   Queue sizes:"
  stats.queues.each do |queue_name, size|
    puts "     - #{queue_name}: #{size} jobs"
  end
rescue => e
  puts "   ✗ Failed to get stats: #{e.message}"
end

# 3. Check Cron Jobs
puts "\n3. SIDEKIQ CRON JOBS:"
begin
  require 'sidekiq/cron/job'
  
  jobs = Sidekiq::Cron::Job.all
  if jobs.empty?
    puts "   ✗ NO CRON JOBS LOADED!"
    puts "   This is the problem - cron jobs need to be loaded"
  else
    puts "   ✓ Found #{jobs.size} cron jobs"
    
    jobs.each do |job|
      puts "\n   Job: #{job.name}"
      puts "     - Class: #{job.klass}"
      puts "     - Cron: #{job.cron}"
      puts "     - Queue: #{job.queue || 'default'}"
      puts "     - Status: #{job.status}"
      puts "     - Last enqueue: #{job.last_enqueue_time || 'NEVER'}"
      
      # Check if job hasn't run recently
      if job.last_enqueue_time.nil?
        puts "     ⚠️  WARNING: This job has NEVER been enqueued!"
      elsif job.last_enqueue_time < 1.day.ago && job.cron.include?("* * *")
        puts "     ⚠️  WARNING: Daily job hasn't run in over 24 hours!"
      elsif job.last_enqueue_time < 1.hour.ago && job.cron.include?("* * * *")
        puts "     ⚠️  WARNING: Hourly job hasn't run in over 1 hour!"
      end
    end
  end
rescue LoadError => e
  puts "   ✗ sidekiq-cron not loaded: #{e.message}"
rescue => e
  puts "   ✗ Failed to check cron jobs: #{e.message}"
end

# 4. Check Running Processes
puts "\n4. SIDEKIQ PROCESSES:"
begin
  processes = Sidekiq::ProcessSet.new
  if processes.size == 0
    puts "   ✗ No Sidekiq processes running!"
    puts "   Start Sidekiq with: sudo systemctl start sidekiq"
  else
    processes.each do |process|
      puts "   Process #{process['identity']}:"
      puts "     - Hostname: #{process['hostname']}"
      puts "     - Started: #{Time.at(process['started_at'])}"
      puts "     - Queues: #{process['queues'].join(', ')}"
      puts "     - Threads: #{process['concurrency']}"
      puts "     - Busy: #{process['busy']}"
    end
  end
rescue => e
  puts "   ✗ Failed to check processes: #{e.message}"
end

# 5. Check for Recent Errors
puts "\n5. RECENT ERRORS:"
begin
  dead_set = Sidekiq::DeadSet.new
  if dead_set.size == 0
    puts "   ✓ No dead jobs"
  else
    puts "   ⚠️  Found #{dead_set.size} dead jobs"
    # Show last 5 dead jobs
    dead_set.first(5).each do |job|
      puts "     - #{job.klass} failed at #{job.at}"
      puts "       Error: #{job.item['error_message']}"
    end
  end
rescue => e
  puts "   ✗ Failed to check dead jobs: #{e.message}"
end

# 6. Manual Cron Job Load Attempt
puts "\n6. ATTEMPTING TO LOAD CRON JOBS:"
begin
  schedule_file = Rails.root.join("config/sidekiq_schedule.yml")
  if File.exist?(schedule_file)
    puts "   Found schedule file: #{schedule_file}"
    schedule = YAML.load_file(schedule_file)
    puts "   Loaded #{schedule.keys.size} job definitions from YAML"
    
    # Try to load them
    result = Sidekiq::Cron::Job.load_from_hash(schedule)
    if result
      puts "   ✓ Successfully loaded cron jobs!"
    else
      puts "   ✗ Failed to load cron jobs (returned false)"
    end
  else
    puts "   ✗ Schedule file not found: #{schedule_file}"
  end
rescue => e
  puts "   ✗ Failed to load schedule: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(3).join("\n     ")}"
end

# 7. Test Job Enqueue
puts "\n7. TEST JOB ENQUEUE:"
begin
  # Try to enqueue a test job
  test_job = Sidekiq::Cron::Job.find('schedule_send_reminders')
  if test_job
    puts "   Found 'schedule_send_reminders' job"
    if test_job.enque!
      puts "   ✓ Successfully enqueued test job!"
      puts "   Check if it appears in the queue"
    else
      puts "   ✗ Failed to enqueue test job"
    end
  else
    puts "   ✗ Could not find a job to test"
  end
rescue => e
  puts "   ✗ Test enqueue failed: #{e.message}"
end

puts "\n" + "=" * 50
puts "DIAGNOSIS COMPLETE"
puts "=" * 50

puts "\nRECOMMENDED ACTIONS:"
puts "1. If no cron jobs are loaded:"
puts "   - Restart Sidekiq: sudo systemctl restart sidekiq"
puts "   - Check logs: sudo journalctl -u sidekiq -n 100"
puts ""
puts "2. If Sidekiq is not running:"
puts "   - Start it: sudo systemctl start sidekiq"
puts "   - Enable auto-start: sudo systemctl enable sidekiq"
puts ""
puts "3. To manually trigger a job:"
puts "   - In console: KnowledgeQuiz.new.perform"
puts "   - Or: SendReminders.new.perform"
puts ""
puts "4. Check the web UI:"
puts "   - Visit: https://memverse.com/sidekiq"
puts "   - Click 'Cron' tab to see scheduled jobs"
puts "   - Use 'Enqueue Now' button to test"