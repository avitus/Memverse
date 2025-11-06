# frozen_string_literal: true

# Helper module for live quiz feature tests
# Provides reusable methods for setting up and testing live quiz functionality
module LiveQuizHelpers
  # Set up a complete quiz ready for live participation
  # @param quiz [Quiz] The quiz to set up
  # @param options [Hash] Options for quiz setup
  # @option options [Integer] :quiz_length Quiz duration in seconds (default: 1200)
  # @option options [Time] :start_time Quiz start time (default: 1.minute.ago)
  # @option options [Integer] :question_count Number of questions to create (default: 1)
  def setup_complete_quiz(quiz, options = {})
    quiz_length = options[:quiz_length] || 1200
    start_time = options[:start_time] || 1.minute.ago
    question_count = options[:question_count] || 1

    # Update quiz attributes to make it "ready"
    quiz.update!(
      quiz_length: quiz_length,
      start_time: start_time
    )

    # Create quiz questions if needed
    question_count.times do |i|
      FactoryBot.create(:quiz_question,
        quiz: quiz,
        question_no: i + 1
      )
    end

    quiz
  end

  # Set up quiz session in Redis with proper synchronization
  # @param quiz_id [Integer] The quiz ID
  # @param status [String] The status to set (default: "in_progress")
  # @param metadata [Hash] Additional metadata for the session
  # @return [QuizSession] The configured quiz session
  def setup_quiz_session_with_sync(quiz_id, status = "in_progress", metadata = {})
    quiz_session = QuizSession.new(quiz_id)

    # Set the status with metadata
    default_metadata = { started_at: Time.current }
    quiz_session.set_quiz_status(status, default_metadata.merge(metadata))

    # Wait for Redis data to be visible across processes
    wait_for_redis_sync do
      session = QuizSession.new(quiz_id)
      session.get_quiz_status == status
    end

    quiz_session
  end

  # Wait for Redis data to be synchronized across processes
  # @param timeout [Integer] Maximum time to wait in seconds
  # @yield Block that should return true when data is synchronized
  def wait_for_redis_sync(timeout: 2, &block)
    start_time = Time.current
    Timeout.timeout(timeout) do
      loop do
        result = block.call
        if result
          elapsed = Time.current - start_time
          puts "Redis sync successful after #{(elapsed * 1000).round(2)}ms"
          return true
        end
        sleep 0.1
      end
    end
  rescue Timeout::Error
    raise "Redis synchronization timeout after #{timeout} seconds"
  end

  # Create and setup a ChatChannel for a quiz
  # @param quiz_id [Integer] The quiz ID
  # @return [ChatChannel] The created chat channel
  def setup_quiz_chat_channel(quiz_id)
    channel_name = "quiz-#{quiz_id}"

    # ChatChannel uses Redis, so we need to ensure it exists
    channel = ChatChannel.new(channel_name)
    channel.status = "Open"

    # Verify it was created
    wait_for_redis_sync do
      ChatChannel.find(channel_name).present?
    end

    channel
  end

  # Visit the live quiz page and wait for it to load
  # @param quiz [Quiz] The quiz to visit
  # @param legacy [Boolean] Whether to use legacy view (default: false)
  def visit_live_quiz_and_wait(quiz, legacy: false)
    url = "/live_quiz/#{quiz.id}"
    url += "?legacy=true" if legacy

    begin
      visit url
    rescue => e
      puts "\n!!! Exception during visit: #{e.class}: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      raise
    end

    # Debug output if page doesn't load as expected
    unless page.has_selector?('.white-box-with-margins, .quiz-schedule-compact', wait: 2)
      puts "\n=== Page Debug Info ==="
      puts "Current path: #{current_path}"
      puts "Page status: #{page.status_code}" rescue nil
      puts "Page title: #{page.title}"
      puts "Flash messages: #{page.find('.alert, .notice').text}" rescue "No flash messages"
      puts "Body text (first 500 chars): #{page.text[0..500]}"

      # Check if we're getting a 404 and diagnose why
      if page.text.include?("doesn't exist") || current_path != url
        puts "\n--- 404 Debug ---"
        puts "Expected URL: #{url}"
        puts "Actual path: #{current_path}"
        # Try to check if the quiz exists in database
        begin
          found_quiz = Quiz.find(quiz.id)
          puts "Quiz exists in DB: #{found_quiz.inspect}"
        rescue
          puts "Quiz NOT found in database!"
        end
      end
      puts "==================="
    end

    # Wait for page to be ready - check for either quiz interface or schedule
    expect(page).to have_selector('.white-box-with-margins, .quiz-schedule-compact', wait: 5)
  end

  # Check if the quiz interface is showing (not the schedule)
  # @return [Boolean] True if quiz interface is visible
  def quiz_interface_visible?
    page.has_css?('.white-box-with-margins', wait: 0)
  end

  # Get JavaScript variables from the page
  # @param var_names [Array<String>] Variable names to retrieve
  # @return [Hash] Hash of variable names to values
  def get_js_variables(*var_names)
    var_names.each_with_object({}) do |var_name, hash|
      hash[var_name] = page.evaluate_script(var_name)
    end
  end

  # Check chat configuration for modern view
  # @param expected_name [String] Expected user name
  # @param expected_login [String] Expected user login
  def verify_modern_chat_config(expected_name:, expected_login:)
    js_vars = get_js_variables('memverseUserName', 'memverseUserLogin')

    expect(js_vars['memverseUserName']).to eq(expected_name)
    expect(js_vars['memverseUserLogin']).to eq(expected_login)
  end

  # Check chat configuration for legacy view
  # @param expected_name [String] Expected user name
  def verify_legacy_chat_config(expected_name:)
    within '#chat_window' do
      sender_value = find('#sender', visible: false).value
      expect(sender_value).to eq(expected_name)
    end
  end

  # Debug helper to print current quiz state
  # @param quiz [Quiz] The quiz to debug
  def debug_quiz_state(quiz)
    puts "=== Quiz State Debug ==="
    puts "Quiz ID: #{quiz.id}"
    puts "Quiz Length: #{quiz.quiz_length}"
    puts "Start Time: #{quiz.start_time}"
    puts "Open?: #{quiz.open?}"
    puts "In Progress?: #{quiz.in_progress?}"

    session = QuizSession.new(quiz.id)
    puts "Session Status: #{session.get_quiz_status}"
    puts "Session In Progress?: #{session.quiz_in_progress?}"

    puts "Current Path: #{current_path}"
    puts "Page Title: #{page.title}"
    puts "==================="
  end
end

# Include the helper in RSpec configuration
RSpec.configure do |config|
  config.include LiveQuizHelpers, type: :feature
end