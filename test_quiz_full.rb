#!/usr/bin/env ruby
# Full automated quiz testing script

require 'time'
require 'fileutils'
require 'open3'

class QuizFullTester
  def initialize
    @quiz_id = 2
    @log_dir = "quiz_test_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    FileUtils.mkdir_p(@log_dir)
    @main_log = File.join(@log_dir, "main.log")
    log("=== Quiz Full Test Started ===")
    log("Test directory: #{@log_dir}")
  end

  def log(msg, file = @main_log)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    message = "[#{timestamp}] #{msg}"
    puts message
    File.open(file, 'a') { |f| f.puts message }
  end

  def run_command(cmd, description = nil)
    log("Running: #{description || cmd}")
    stdout, stderr, status = Open3.capture3(cmd)
    log("Output: #{stdout.strip}") unless stdout.strip.empty?
    log("Error: #{stderr.strip}") unless stderr.strip.empty?
    { stdout: stdout, stderr: stderr, status: status.success? }
  end

  def ensure_services_running
    log("\n=== Checking Services ===")
    
    services = {
      "Rails server" => "pgrep -f puma",
      "Sidekiq" => "pgrep -f sidekiq",
      "Redis" => "pgrep -f redis-server"
    }
    
    all_running = true
    services.each do |name, check_cmd|
      result = run_command(check_cmd, "Checking #{name}")
      if result[:status]
        log("✓ #{name} is running (PID: #{result[:stdout].strip})")
      else
        log("✗ #{name} is NOT running!")
        all_running = false
      end
    end
    
    unless all_running
      log("ERROR: Not all required services are running!")
      log("Please ensure Rails, Sidekiq, and Redis are running before testing.")
      return false
    end
    
    true
  end

  def reset_quiz_state
    log("\n=== Resetting Quiz State ===")
    
    # Clear Redis data
    run_command("redis-cli DEL quiz-#{@quiz_id}", "Clearing Redis quiz data")
    run_command("redis-cli DEL quiz:#{@quiz_id}:scores", "Clearing Redis scores")
    
    # Update quiz in database
    rails_cmd = <<~RUBY
      quiz = Quiz.find(#{@quiz_id})
      quiz.update!(start_time: 2.minutes.from_now)
      puts "Quiz ##{@quiz_id} will start at: \#{quiz.start_time}"
      
      # Ensure quiz has questions
      if quiz.quiz_questions.count == 0
        puts "WARNING: Quiz has no questions!"
      else
        puts "Quiz has \#{quiz.quiz_questions.count} questions"
      end
    RUBY
    
    result = run_command("bundle exec rails runner \"#{rails_cmd}\"", "Setting quiz start time")
    log("Rails output: #{result[:stdout]}")
  end

  def start_monitors
    log("\n=== Starting Background Monitors ===")
    
    @monitors = []
    
    # Monitor Sidekiq logs
    sidekiq_monitor = fork do
      File.open(File.join(@log_dir, "sidekiq_monitor.log"), 'w') do |f|
        IO.popen("tail -f log/sidekiq.log | grep -E 'Quiz ##{@quiz_id}|ScheduledQuiz'") do |io|
          io.each_line do |line|
            f.puts "[#{Time.now.strftime('%H:%M:%S')}] #{line}"
            f.flush
            
            # Check for key events
            if line.include?("Step 1/7")
              puts "✓ Quiz announcement started!"
            elsif line.include?("Step 4/7")
              puts "✓ Quiz questions started!"
            elsif line.include?("COMPLETED!")
              puts "✓ Quiz completed!"
            end
          end
        end
      end
    end
    @monitors << sidekiq_monitor
    
    # Monitor Redis state
    redis_monitor = fork do
      File.open(File.join(@log_dir, "redis_monitor.log"), 'w') do |f|
        loop do
          f.puts "=== Redis State at #{Time.now} ==="
          f.puts `redis-cli HGETALL quiz-#{@quiz_id} 2>&1`
          f.puts `redis-cli ZRANGE quiz:#{@quiz_id}:scores 0 -1 WITHSCORES 2>&1`
          f.puts ""
          f.flush
          sleep 10
        end
      end
    end
    @monitors << redis_monitor
    
    log("Started #{@monitors.length} monitor processes")
  end

  def test_quiz_page
    log("\n=== Testing Quiz Page ===")
    
    # Test page load
    result = run_command(
      "curl -s -o #{File.join(@log_dir, 'quiz_page.html')} -w '%{http_code}' http://localhost:3000/live_quiz/#{@quiz_id}",
      "Fetching quiz page"
    )
    
    http_code = result[:stdout].strip
    log("HTTP Status Code: #{http_code}")
    
    if http_code == "200"
      # Check page content
      page_content = File.read(File.join(@log_dir, 'quiz_page.html'))
      
      checks = {
        "Question containers" => page_content.scan(/id="question-\d+"/).count,
        "Chat stream" => page_content.include?('id="chat-stream-narrow"'),
        "Quiz timer" => page_content.include?('id="quiz-timer"'),
        "Scoreboard" => page_content.include?('id="live-quiz-scores"'),
        "PubNub config" => page_content.include?('new PubNub')
      }
      
      log("Page element checks:")
      checks.each do |element, result|
        status = result.is_a?(Integer) ? "#{result} found" : (result ? "✓ Found" : "✗ Not found")
        log("  #{element}: #{status}")
      end
      
      # Save key JavaScript variables
      if page_content =~ /var channel = "quiz-(\d+)"/
        log("Quiz channel: quiz-#{$1}")
      end
    else
      log("ERROR: Quiz page returned status #{http_code}")
    end
  end

  def wait_for_quiz_completion(max_wait = 300)
    log("\n=== Waiting for Quiz Completion ===")
    start_time = Time.now
    
    while (Time.now - start_time) < max_wait
      # Check if quiz completed in Sidekiq log
      if File.exist?("log/sidekiq.log") && File.read("log/sidekiq.log").include?("Quiz ##{@quiz_id}.*COMPLETED")
        log("Quiz completed!")
        return true
      end
      
      # Show progress
      elapsed = (Time.now - start_time).to_i
      remaining = max_wait - elapsed
      print "\rWaiting for quiz... #{elapsed}s elapsed, #{remaining}s remaining"
      
      sleep 5
    end
    
    log("\nTimeout waiting for quiz completion")
    false
  end

  def generate_report
    log("\n=== Generating Test Report ===")
    
    report_file = File.join(@log_dir, "TEST_REPORT.md")
    File.open(report_file, 'w') do |f|
      f.puts "# Quiz Test Report"
      f.puts "Generated: #{Time.now}"
      f.puts ""
      
      f.puts "## Test Configuration"
      f.puts "- Quiz ID: #{@quiz_id}"
      f.puts "- Test Directory: #{@log_dir}"
      f.puts ""
      
      f.puts "## Services Status"
      f.puts "- Rails: ✓ Running"
      f.puts "- Sidekiq: ✓ Running"
      f.puts "- Redis: ✓ Running"
      f.puts ""
      
      f.puts "## Quiz Execution"
      if File.exist?(File.join(@log_dir, "sidekiq_monitor.log"))
        sidekiq_log = File.read(File.join(@log_dir, "sidekiq_monitor.log"))
        
        stages = [
          ["Announcement", "Step 1/7"],
          ["Chat Period", "Step 2/7"],
          ["Questions", "Step 4/7"],
          ["Completion", "COMPLETED"]
        ]
        
        stages.each do |stage_name, pattern|
          if sidekiq_log.include?(pattern)
            f.puts "- #{stage_name}: ✓ Completed"
          else
            f.puts "- #{stage_name}: ✗ Not detected"
          end
        end
      end
      f.puts ""
      
      f.puts "## Logs Generated"
      Dir.glob(File.join(@log_dir, "*")).each do |file|
        f.puts "- #{File.basename(file)}"
      end
    end
    
    log("Report saved to: #{report_file}")
    
    # Display report
    puts "\n" + "="*50
    puts File.read(report_file)
    puts "="*50
  end

  def cleanup
    log("\n=== Cleaning Up ===")
    @monitors&.each do |pid|
      Process.kill("TERM", pid) rescue nil
    end
    Process.waitall
    log("Cleanup complete")
  end

  def run
    begin
      return unless ensure_services_running
      
      reset_quiz_state
      start_monitors
      
      # Wait a bit for quiz to be scheduled
      sleep 10
      
      test_quiz_page
      
      # Wait for quiz to complete
      wait_for_quiz_completion
      
      # Generate final report
      generate_report
      
    ensure
      cleanup
    end
  end
end

# Run if executed directly
if __FILE__ == $0
  tester = QuizFullTester.new
  tester.run
end