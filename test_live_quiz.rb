#!/usr/bin/env ruby
# Script to test live quiz functionality automatically

require 'net/http'
require 'json'
require 'time'
require 'fileutils'

class LiveQuizTester
  def initialize(quiz_id = 2)
    @quiz_id = quiz_id
    @base_url = "http://localhost:3000"
    @log_file = "quiz_test_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log"
  end

  def log(message)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    log_message = "[#{timestamp}] #{message}"
    puts log_message
    File.open(@log_file, 'a') { |f| f.puts log_message }
  end

  def run_rails_command(command)
    log("Executing Rails command: #{command}")
    result = `bundle exec rails runner "#{command}" 2>&1`
    log("Result: #{result.strip}")
    result
  end

  def check_server_status
    uri = URI(@base_url)
    begin
      response = Net::HTTP.get_response(uri)
      response.code == "200"
    rescue
      false
    end
  end

  def update_quiz_start_time(minutes_from_now = 5)
    log("=== UPDATING QUIZ START TIME ===")
    command = <<~RUBY
      quiz = Quiz.find(#{@quiz_id})
      new_time = #{minutes_from_now}.minutes.from_now
      quiz.update!(start_time: new_time)
      puts "Quiz ##{@quiz_id} start time updated to: \#{quiz.start_time}"
    RUBY
    run_rails_command(command)
  end

  def check_quiz_page
    log("=== CHECKING QUIZ PAGE ACCESSIBILITY ===")
    uri = URI("#{@base_url}/live_quiz/#{@quiz_id}")
    response = Net::HTTP.get_response(uri)
    
    if response.code == "302"
      log("Quiz page requires authentication (redirected)")
      return false
    elsif response.code == "200"
      log("Quiz page loaded successfully")
      
      # Check for key elements
      body = response.body
      elements = {
        "Question containers" => body.scan(/id="question-\d+"/).count,
        "Chat stream" => body.include?('id="chat-stream-narrow"'),
        "Quiz timer" => body.include?('id="quiz-timer"'),
        "Scoreboard" => body.include?('id="live-quiz-scores"'),
        "PubNub config" => body.include?('subscribeKey:')
      }
      
      log("Page elements found:")
      elements.each do |name, found|
        log("  - #{name}: #{found}")
      end
      
      return true
    else
      log("Quiz page returned unexpected status: #{response.code}")
      return false
    end
  end

  def monitor_sidekiq_logs(duration_seconds = 300)
    log("=== MONITORING SIDEKIQ LOGS ===")
    start_time = Time.now
    last_line_count = 0
    
    while (Time.now - start_time) < duration_seconds
      # Check sidekiq log for quiz activity
      log_content = `tail -100 log/sidekiq.log | grep -E "Quiz ##{@quiz_id}|ScheduledQuiz" 2>&1`
      lines = log_content.split("\n")
      
      if lines.count > last_line_count
        new_lines = lines[last_line_count..-1]
        new_lines.each { |line| log("SIDEKIQ: #{line}") }
        
        # Check for specific events
        if new_lines.any? { |l| l.include?("Step 1/7 - Announcing quiz") }
          log("✓ Quiz announcement started!")
        end
        
        if new_lines.any? { |l| l.include?("Step 2/7 - Starting chat period") }
          log("✓ Chat period started!")
        end
        
        if new_lines.any? { |l| l.include?("Step 4/7 - Running quiz questions") }
          log("✓ Quiz questions started!")
        end
        
        if new_lines.any? { |l| l.include?("COMPLETED! Total duration:") }
          log("✓ Quiz completed successfully!")
          break
        end
        
        last_line_count = lines.count
      end
      
      sleep 5
    end
  end

  def check_redis_data
    log("=== CHECKING REDIS DATA ===")
    
    # Check for quiz data in Redis
    redis_commands = [
      "EXISTS quiz-#{@quiz_id}",
      "HGETALL quiz-#{@quiz_id}",
      "ZRANGE quiz:#{@quiz_id}:scores 0 -1 WITHSCORES"
    ]
    
    redis_commands.each do |cmd|
      result = `redis-cli #{cmd} 2>&1`.strip
      log("Redis command '#{cmd}': #{result}")
    end
  end

  def simulate_user_interaction
    log("=== SIMULATING USER INTERACTION ===")
    
    # This would require authentication - for now just log what we would do
    log("Would perform:")
    log("  - Join quiz channel via PubNub")
    log("  - Send chat messages")
    log("  - Submit quiz answers")
    log("  - Check scoreboard updates")
  end

  def generate_report
    log("\n=== FINAL REPORT ===")
    log("Test log saved to: #{@log_file}")
    
    # Check final quiz status
    quiz_status = run_rails_command("puts Quiz.find(#{@quiz_id}).start_time")
    log("Final quiz start time: #{quiz_status}")
    
    # Summary
    log("\nTest Summary:")
    log("- Server Status: #{check_server_status ? 'Running' : 'Not Running'}")
    log("- Quiz Page Accessible: #{check_quiz_page ? 'Yes' : 'No'}")
    log("- Check log file for detailed results: #{@log_file}")
  end

  def run_full_test
    log("=== STARTING LIVE QUIZ TEST ===")
    log("Testing Quiz ID: #{@quiz_id}")
    log("Test log: #{@log_file}")
    
    # Step 1: Check server
    unless check_server_status
      log("ERROR: Server not running! Please start with: bundle exec rails server")
      return
    end
    
    # Step 2: Update quiz start time
    update_quiz_start_time(3) # Start in 3 minutes
    
    # Step 3: Check quiz page loads
    sleep 2
    check_quiz_page
    
    # Step 4: Monitor sidekiq for quiz execution
    log("\nMonitoring quiz execution (this will take a few minutes)...")
    monitor_sidekiq_logs(240) # Monitor for 4 minutes
    
    # Step 5: Check Redis data
    check_redis_data
    
    # Step 6: Generate report
    generate_report
  end
end

# Run the test if executed directly
if __FILE__ == $0
  tester = LiveQuizTester.new
  tester.run_full_test
end