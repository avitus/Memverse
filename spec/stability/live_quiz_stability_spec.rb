require 'rails_helper'
require 'benchmark'

RSpec.describe 'Live Quiz Stability Testing', type: :request do
  include FactoryBot::Syntax::Methods
  include Devise::Test::IntegrationHelpers
  let(:quiz) { create(:quiz, id: 1) }
  let(:user) { create(:user) }

  before do
    # Create sufficient quiz questions
    create_list(:quiz_question, 50, :mcq, quiz: quiz, approval_status: 'approved')

    # Mock external services
    allow(PN).to receive(:publish).and_return(true)

    # Clean Redis
    $redis.flushdb
  end

  describe 'Long-duration connection stability' do
    it 'maintains SSE connection stability over 2 hours' do
      skip 'Stability test - run manually with STABILITY_TEST=true' unless ENV['STABILITY_TEST']

      sign_in user

      connection_start = Time.current
      connection_errors = []
      heartbeats_received = 0
      state_updates_received = 0

      # Start SSE connection in a thread
      connection_thread = Thread.new do
        begin
          uri = URI("http://localhost:3000/live_quiz/events?id=#{quiz.id}")

          Net::HTTP.start(uri.host, uri.port, read_timeout: 7200) do |http|
            request = Net::HTTP::Get.new(uri)
            request['Accept'] = 'text/event-stream'
            request['Cache-Control'] = 'no-cache'
            request['Authorization'] = "Bearer #{user.authentication_token}"

            http.request(request) do |response|
              response.read_body do |chunk|
                # Parse SSE events
                if chunk.include?(':heartbeat')
                  heartbeats_received += 1
                elsif chunk.include?('event: quiz-state')
                  state_updates_received += 1
                end
              end
            end
          end
        rescue => e
          connection_errors << {
            time: Time.current - connection_start,
            error: e.class.name,
            message: e.message
          }
        end
      end

      # Monitor connection for 2 hours
      monitoring_duration = ENV['QUICK_TEST'] ? 60 : 7200 # 1 minute for quick test, 2 hours for full
      monitoring_thread = Thread.new do
        start_time = Time.current

        while (Time.current - start_time) < monitoring_duration
          # Periodically trigger state changes to test broadcasts
          if Time.current.to_i % 300 == 0  # Every 5 minutes
            Redis.current.publish("quiz:#{quiz.id}:state", {
              state: 'waiting',
              timestamp: Time.current.utc.iso8601
            }.to_json)
          end

          sleep(10)
        end
      end

      # Wait for test to complete
      monitoring_thread.join
      connection_thread.kill

      # Analyze results
      connection_duration = Time.current - connection_start
      expected_heartbeats = (monitoring_duration / 30).to_i  # One heartbeat every 30 seconds

      puts "\n\nConnection Stability Results:"
      puts "Duration: #{connection_duration.round} seconds"
      puts "Heartbeats received: #{heartbeats_received} (expected: ~#{expected_heartbeats})"
      puts "State updates received: #{state_updates_received}"
      puts "Connection errors: #{connection_errors.size}"

      connection_errors.each do |error|
        puts "  - Error at #{error[:time].round}s: #{error[:error]} - #{error[:message]}"
      end

      # Verify stability
      expect(connection_errors).to be_empty, "Connection had #{connection_errors.size} errors"
      expect(heartbeats_received).to be > (expected_heartbeats * 0.9),
        "Too few heartbeats received: #{heartbeats_received}"
    end
  end

  describe 'Repeated quiz cycle stability' do
    it 'handles 10 back-to-back quiz cycles without degradation' do
      skip 'Stability test - run manually with STABILITY_TEST=true' unless ENV['STABILITY_TEST']

      cycle_times = []
      errors = []
      memory_samples = []

      10.times do |cycle|
        cycle_start = Time.current
        initial_memory = GetProcessMem.new.mb

        begin
          # Initialize QuizSession
          quiz_session = QuizSession.new(quiz.id)

          # Simulate quiz preparation
          quiz_session.set_quiz_status("In progress. Initializing...")
          sleep(1)

          # Simulate chat period
          quiz_session.set_quiz_status("In progress. Chat open. Wait for question.", {
            chat_start_time: Time.current.utc.iso8601,
            chat_duration: 5  # Short duration for testing
          })
          sleep(5)

          # Simulate quiz questions
          5.times do |q_num|
            quiz_session.set_quiz_status("Question #{q_num + 1} in progress")

            # Simulate participants submitting scores
            10.times do |participant_idx|
              quiz_session.add_participant(
                participant_idx,
                "TestUser#{participant_idx}",
                "testuser#{participant_idx}"
              )
              quiz_session.update_score(participant_idx, q_num + 1, rand(0..10))
            end

            sleep(2)  # Simulate question duration
          end

          # Finalize quiz
          quiz_session.set_quiz_status("Finished", {
            end_time: Time.current.utc.iso8601
          })

          # Clean up quiz data
          quiz_session.cleanup_quiz_data

          cycle_time = Time.current - cycle_start
          cycle_times << cycle_time

          final_memory = GetProcessMem.new.mb
          memory_samples << {
            cycle: cycle + 1,
            initial: initial_memory,
            final: final_memory,
            increase: final_memory - initial_memory
          }

        rescue => e
          errors << {
            cycle: cycle + 1,
            error: e.class.name,
            message: e.message
          }
        end

        # Brief pause between cycles
        sleep(5)
      end

      # Analyze results
      avg_cycle_time = cycle_times.sum / cycle_times.size
      cycle_time_variance = cycle_times.map { |t| (t - avg_cycle_time).abs }.max

      total_memory_increase = memory_samples.last[:final] - memory_samples.first[:initial]

      puts "\n\nRepeated Quiz Cycle Results:"
      puts "Cycles completed: #{cycle_times.size}/10"
      puts "Average cycle time: #{avg_cycle_time.round(2)}s"
      puts "Cycle time variance: #{cycle_time_variance.round(2)}s"
      puts "Total memory increase: #{total_memory_increase.round(2)}MB"
      puts "Errors: #{errors.size}"

      # Display memory trend
      puts "\nMemory usage by cycle:"
      memory_samples.each do |sample|
        puts "  Cycle #{sample[:cycle]}: #{sample[:initial].round(1)}MB → #{sample[:final].round(1)}MB " +
             "(+#{sample[:increase].round(1)}MB)"
      end

      # Verify stability
      expect(errors).to be_empty, "#{errors.size} errors occurred during cycles"
      expect(cycle_time_variance).to be < 5,
        "Cycle times varied too much: #{cycle_time_variance}s"
      expect(total_memory_increase).to be < 50,
        "Memory increased by #{total_memory_increase}MB over 10 cycles"
    end
  end

  describe 'Memory usage over time' do
    it 'maintains stable memory usage during extended operation' do
      skip 'Stability test - run manually with STABILITY_TEST=true' unless ENV['STABILITY_TEST']

      test_duration = ENV['QUICK_TEST'] ? 300 : 3600  # 5 minutes or 1 hour
      sample_interval = 30  # Sample every 30 seconds

      memory_samples = []
      gc_stats = []
      start_time = Time.current
      initial_memory = GetProcessMem.new.mb

      # Create background load
      load_threads = []
      5.times do |i|
        load_threads << Thread.new do
          user = create(:user)

          while (Time.current - start_time) < test_duration
            begin
              # Simulate various operations
              quiz_session = QuizSession.new(quiz.id)

              # Add and remove participants
              5.times do |j|
                idx = i * 10 + j
                quiz_session.add_participant(idx, "User#{idx}", "user#{idx}")
                quiz_session.update_score(idx, 1, rand(0..10))
              end

              # Get scoreboard
              quiz_session.get_scoreboard

              # Simulate state changes
              Redis.current.publish("quiz:#{quiz.id}:state", {
                state: ['waiting', 'preparing', 'ready', 'running'].sample,
                timestamp: Time.current.utc.iso8601
              }.to_json)

              sleep(rand(1..5))
            rescue => e
              # Log but don't fail
              puts "Load thread error: #{e.message}"
            end
          end
        end
      end

      # Monitor memory usage
      monitoring_thread = Thread.new do
        while (Time.current - start_time) < test_duration
          current_memory = GetProcessMem.new.mb
          gc_stat = GC.stat

          memory_samples << {
            time: Time.current - start_time,
            memory: current_memory,
            delta: current_memory - initial_memory
          }

          gc_stats << {
            time: Time.current - start_time,
            count: gc_stat[:count],
            heap_pages: gc_stat[:heap_allocated_pages],
            heap_slots: gc_stat[:heap_live_slots]
          }

          sleep(sample_interval)
        end
      end

      # Wait for test completion
      monitoring_thread.join
      load_threads.each(&:kill)

      # Analyze results
      final_memory = GetProcessMem.new.mb
      max_memory = memory_samples.map { |s| s[:memory] }.max
      avg_memory = memory_samples.map { |s| s[:memory] }.sum / memory_samples.size

      # Check for memory leaks (linear growth)
      memory_values = memory_samples.map { |s| s[:memory] }
      time_values = memory_samples.map { |s| s[:time] }

      # Simple linear regression
      n = memory_values.size
      if n > 1
        sum_x = time_values.sum
        sum_y = memory_values.sum
        sum_xy = time_values.zip(memory_values).map { |x, y| x * y }.sum
        sum_x2 = time_values.map { |x| x ** 2 }.sum

        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x ** 2)
        memory_growth_per_hour = slope * 3600
      else
        memory_growth_per_hour = 0
      end

      puts "\n\nMemory Stability Results:"
      puts "Test duration: #{(Time.current - start_time).round}s"
      puts "Initial memory: #{initial_memory.round(2)}MB"
      puts "Final memory: #{final_memory.round(2)}MB"
      puts "Max memory: #{max_memory.round(2)}MB"
      puts "Average memory: #{avg_memory.round(2)}MB"
      puts "Memory growth rate: #{memory_growth_per_hour.round(2)}MB/hour"
      puts "GC runs: #{gc_stats.last[:count] - gc_stats.first[:count]}"

      # Verify memory stability
      expect(final_memory - initial_memory).to be < 100,
        "Memory increased by #{(final_memory - initial_memory).round(2)}MB"
      expect(memory_growth_per_hour).to be < 50,
        "Memory growing at #{memory_growth_per_hour.round(2)}MB/hour"
    end
  end

  describe 'Redis connection stability' do
    it 'maintains stable Redis connections under sustained load' do
      skip 'Stability test - run manually with STABILITY_TEST=true' unless ENV['STABILITY_TEST']

      test_duration = 300  # 5 minutes
      connection_errors = []
      pubsub_errors = []

      # Create multiple Redis pub/sub connections
      subscriber_threads = []
      20.times do |i|
        subscriber_threads << Thread.new do
          begin
            redis = Redis.new
            redis.subscribe("quiz:#{quiz.id}:state", "quiz:test:#{i}") do |on|
              on.message do |channel, message|
                # Process message
              end
            end
          rescue => e
            pubsub_errors << {
              thread: i,
              error: e.class.name,
              message: e.message
            }
          end
        end
      end

      # Generate sustained Redis load
      load_thread = Thread.new do
        start_time = Time.current
        operations = 0

        while (Time.current - start_time) < test_duration
          begin
            # Various Redis operations
            Redis.current.set("test:key:#{operations}", "value")
            Redis.current.get("test:key:#{operations}")
            Redis.current.del("test:key:#{operations - 100}") if operations > 100

            # Publish messages
            if operations % 10 == 0
              20.times do |i|
                Redis.current.publish("quiz:test:#{i}", "test message #{operations}")
              end
            end

            operations += 1
            sleep(0.01)  # 100 ops/second
          rescue => e
            connection_errors << {
              operation: operations,
              error: e.class.name,
              message: e.message
            }
          end
        end
      end

      # Wait for test completion
      load_thread.join
      subscriber_threads.each(&:kill)

      puts "\n\nRedis Stability Results:"
      puts "Connection errors: #{connection_errors.size}"
      puts "Pub/Sub errors: #{pubsub_errors.size}"

      # Verify Redis stability
      expect(connection_errors.size).to be < 10,
        "Too many Redis connection errors: #{connection_errors.size}"
      expect(pubsub_errors.size).to be < 5,
        "Too many pub/sub errors: #{pubsub_errors.size}"

      # Verify Redis is still responsive
      expect { Redis.current.ping }.not_to raise_error
    end
  end
end