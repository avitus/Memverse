#!/usr/bin/env ruby
# Test script to verify Sidekiq cron job configuration

require_relative 'config/environment'
require 'sidekiq/cron/job'

puts "=" * 80
puts "SIDEKIQ CRON JOB CONFIGURATION TEST"
puts "=" * 80

# Load the schedule file
schedule_file = Rails.root.join("config/sidekiq_schedule.yml")
if File.exist?(schedule_file)
  puts "\n✓ Schedule file found: #{schedule_file}"
  
  begin
    schedule = YAML.load_file(schedule_file)
    puts "✓ Schedule file parsed successfully"
    puts "\nFound #{schedule.keys.size} scheduled jobs:"
    schedule.keys.each { |key| puts "  - #{key}" }
    
    # Try to load the jobs
    puts "\n" + "=" * 80
    puts "ATTEMPTING TO LOAD JOBS INTO SIDEKIQ-CRON"
    puts "=" * 80
    
    errors = []
    schedule.each do |name, config|
      begin
        # Check if the worker class exists
        worker_class = config['class'].constantize
        puts "\n✓ #{name}:"
        puts "  Class: #{worker_class}"
        puts "  Queue: #{config['queue']}"
        puts "  Cron: #{config['cron']}"
        
        # Check if it's a valid Sidekiq worker
        if worker_class.included_modules.include?(Sidekiq::Worker)
          puts "  ✓ Valid Sidekiq::Worker"
        else
          puts "  ✗ NOT a Sidekiq::Worker!"
          errors << "#{name}: Class #{worker_class} is not a Sidekiq::Worker"
        end
        
        # Check if active_job is specified (it shouldn't be)
        if config['active_job']
          puts "  ⚠ WARNING: active_job: true is set but this is a plain Sidekiq worker!"
          errors << "#{name}: Remove 'active_job: true' from configuration"
        end
        
      rescue NameError => e
        puts "\n✗ #{name}: Class '#{config['class']}' not found!"
        errors << "#{name}: #{e.message}"
      end
    end
    
    if errors.any?
      puts "\n" + "=" * 80
      puts "ERRORS FOUND:"
      puts "=" * 80
      errors.each { |e| puts "  ✗ #{e}" }
    end
    
    # Try to actually load the jobs
    puts "\n" + "=" * 80
    puts "LOADING JOBS INTO SIDEKIQ-CRON"
    puts "=" * 80
    
    begin
      Sidekiq::Cron::Job.load_from_hash(schedule)
      puts "✓ Jobs loaded successfully!"
      
      # List loaded jobs
      puts "\nCurrently loaded cron jobs:"
      Sidekiq::Cron::Job.all.each do |job|
        puts "  - #{job.name}: #{job.klass} (#{job.cron})"
        puts "    Last enqueued: #{job.last_enqueue_time || 'Never'}"
      end
    rescue => e
      puts "✗ Failed to load jobs: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
    
  rescue => e
    puts "✗ Failed to parse schedule file: #{e.message}"
  end
else
  puts "✗ Schedule file not found!"
end

puts "\n" + "=" * 80
puts "TEST COMPLETE"
puts "=" * 80