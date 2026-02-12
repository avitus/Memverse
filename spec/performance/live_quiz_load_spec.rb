require 'rails_helper'
require 'net/http'
require 'benchmark'
require 'concurrent'

RSpec.describe 'Live Quiz Load Testing', type: :request do
  include FactoryBot::Syntax::Methods
  let(:quiz) { create(:quiz, id: 1) }
  let(:users) { create_list(:user, 110) } # Create more users than we'll use concurrently

  before do
    # Create quiz questions for testing
    create_list(:quiz_question, 30, :mcq, quiz: quiz, approval_status: 'approved')

    # Ensure Redis is clean
    $redis.flushdb

    # Mock PubNub to prevent external API calls during load testing
    allow(PN).to receive(:publish).and_return(true)
  end

  describe 'SSE connection load testing' do
    context 'with 100 concurrent connections' do
      it 'handles 100 concurrent SSE connections without degradation' do
        skip 'Load test - run manually with LOAD_TEST=true' unless ENV['LOAD_TEST']

        connection_threads = []
        connection_times = []
        errors = []

        # Measure time to establish 100 concurrent connections
        benchmark_time = Benchmark.measure do
          100.times do |i|
            connection_threads << Thread.new do
              begin
                user = users[i]
                sign_in user

                start_time = Time.current

                # Simulate SSE connection
                get quiz_events_path(id: quiz.id), headers: {
                  'Accept' => 'text/event-stream',
                  'Cache-Control' => 'no-cache'
                }

                connection_time = Time.current - start_time
                connection_times << connection_time

                # Keep connection open for realistic simulation
                sleep(5)
              rescue => e
                errors << { user_id: i, error: e.message }
              end
            end
          end

          # Wait for all connections to establish
          connection_threads.each(&:join)
        end

        # Analyze results
        avg_connection_time = connection_times.sum / connection_times.size
        max_connection_time = connection_times.max

        expect(errors).to be_empty, "Connection errors: #{errors.inspect}"
        expect(avg_connection_time).to be < 0.1, "Average connection time too high: #{avg_connection_time}s"
        expect(max_connection_time).to be < 0.5, "Max connection time too high: #{max_connection_time}s"
        expect(benchmark_time.real).to be < 10, "Total time to establish 100 connections: #{benchmark_time.real}s"
      end
    end

    context 'state broadcasts to many users' do
      it 'broadcasts state changes to 100 users efficiently' do
        skip 'Load test - run manually with LOAD_TEST=true' unless ENV['LOAD_TEST']

        # Set up Redis subscriber threads to simulate 100 connected users
        subscriber_threads = []
        messages_received = Concurrent::AtomicFixnum.new(0)
        broadcast_latencies = Concurrent::Array.new

        100.times do |i|
          subscriber_threads << Thread.new do
            redis = Redis.new
            redis.subscribe("quiz:#{quiz.id}:state") do |on|
              on.message do |channel, message|
                received_at = Time.current
                data = JSON.parse(message)

                if data['timestamp']
                  sent_at = Time.parse(data['timestamp'])
                  latency = received_at - sent_at
                  broadcast_latencies << latency
                end

                messages_received.increment
              end
            end
          end
        end

        # Give subscribers time to connect
        sleep(1)

        # Broadcast state changes
        broadcast_time = Benchmark.measure do
          10.times do |i|
            state_data = {
              state: ['waiting', 'preparing', 'ready', 'running'].sample,
              timestamp: Time.current.utc.iso8601,
              quiz_id: quiz.id
            }

            $redis.publish("quiz:#{quiz.id}:state", state_data.to_json)
            sleep(0.1) # Small delay between broadcasts
          end
        end

        # Wait for messages to be received
        sleep(1)

        # Clean up
        subscriber_threads.each(&:kill)

        # Analyze results
        expected_messages = 100 * 10 # 100 subscribers * 10 broadcasts
        avg_latency = broadcast_latencies.sum / broadcast_latencies.size if broadcast_latencies.any?

        expect(messages_received.value).to eq(expected_messages).tap do
          Rails.logger.info "Expected #{expected_messages} messages, got #{messages_received.value}"
        end
        if avg_latency
          expect(avg_latency).to be < 0.05
          Rails.logger.info "Average broadcast latency: #{avg_latency}s"
        end
      end
    end

    context 'graceful degradation under extreme load' do
      it 'handles 1000+ connection attempts gracefully' do
        skip 'Load test - run manually with LOAD_TEST=true' unless ENV['LOAD_TEST']

        # Create additional users for extreme load test
        extra_users = create_list(:user, 900)
        all_users = users + extra_users

        successful_connections = Concurrent::AtomicFixnum.new(0)
        failed_connections = Concurrent::AtomicFixnum.new(0)
        response_times = Concurrent::Array.new

        # Attempt 1000 connections with rate limiting
        connection_threads = []

        1000.times do |i|
          # Rate limit to prevent overwhelming the server
          sleep(0.01) if i % 50 == 0

          connection_threads << Thread.new do
            begin
              user = all_users[i]

              start_time = Time.current

              # Try to establish connection with timeout
              Timeout::timeout(5) do
                response = Net::HTTP.get_response(
                  URI("http://localhost:3000/live_quiz/events?id=#{quiz.id}"),
                  {
                    'Accept' => 'text/event-stream',
                    'Authorization' => "Bearer #{user.authentication_token}"
                  }
                )

                response_time = Time.current - start_time
                response_times << response_time

                if response.code == '200'
                  successful_connections.increment
                else
                  failed_connections.increment
                end
              end
            rescue => e
              failed_connections.increment
            end
          end
        end

        # Wait for all attempts to complete
        connection_threads.each(&:join)

        # Analyze results
        success_rate = successful_connections.value.to_f / 1000
        avg_response_time = response_times.sum / response_times.size if response_times.any?

        # Under extreme load, we expect graceful degradation
        expect(success_rate).to(be > 0.8) # Success rate should be at least 80%
        if avg_response_time
          expect(avg_response_time).to(be < 2) # Average response time should be under 2 seconds
        end

        # Verify server is still responsive after load
        get quiz_state_path(id: quiz.id)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Resource usage monitoring' do
    it 'monitors memory usage during sustained load' do
      skip 'Load test - run manually with LOAD_TEST=true' unless ENV['LOAD_TEST']

      initial_memory = GetProcessMem.new.mb
      memory_samples = []

      # Create 50 concurrent connections and monitor memory
      threads = []
      50.times do |i|
        threads << Thread.new do
          user = users[i]
          sign_in user

          # Simulate active SSE connection
          10.times do
            get quiz_state_path(id: quiz.id)
            sleep(1)
          end
        end
      end

      # Monitor memory usage
      monitoring_thread = Thread.new do
        10.times do
          memory_samples << GetProcessMem.new.mb
          sleep(1)
        end
      end

      threads.each(&:join)
      monitoring_thread.join

      # Analyze memory usage
      final_memory = GetProcessMem.new.mb
      memory_increase = final_memory - initial_memory
      avg_memory = memory_samples.sum / memory_samples.size

      expect(memory_increase).to be < 100,
        "Memory increased by #{memory_increase}MB during load test"
      expect(avg_memory - initial_memory).to be < 50,
        "Average memory usage too high during test"
    end

    it 'monitors Redis connection pool usage' do
      skip 'Load test - run manually with LOAD_TEST=true' unless ENV['LOAD_TEST']

      pool_stats = []

      # Monitor Redis pool during concurrent access
      monitoring_thread = Thread.new do
        10.times do
          if defined?($redis.connection)
            pool = $redis.instance_variable_get(:@pool)
            if pool
              stats = {
                size: pool.size,
                available: pool.available
              }
              pool_stats << stats
            end
          end
          sleep(0.5)
        end
      end

      # Generate Redis load
      threads = []
      50.times do
        threads << Thread.new do
          10.times do
            $redis.get("test_key_#{rand(100)}")
            $redis.publish("test_channel", "test_message")
            sleep(0.1)
          end
        end
      end

      threads.each(&:join)
      monitoring_thread.join

      # Verify pool didn't exhaust
      exhausted = pool_stats.any? { |stat| stat[:available] == 0 }
      expect(exhausted).to be false, "Redis connection pool was exhausted during test"
    end
  end

  describe 'Response time analysis' do
    it 'measures response times under various load levels' do
      skip 'Load test - run manually with LOAD_TEST=true' unless ENV['LOAD_TEST']

      results = {}

      [10, 25, 50, 100].each do |concurrent_users|
        response_times = Concurrent::Array.new

        threads = []
        concurrent_users.times do |i|
          threads << Thread.new do
            user = users[i]

            5.times do
              start_time = Time.current

              # Make various API calls
              Net::HTTP.get_response(
                URI("http://localhost:3000/live_quiz/quiz_state/#{quiz.id}"),
                { 'Authorization' => "Bearer #{user.authentication_token}" }
              )

              response_times << (Time.current - start_time)
            end
          end
        end

        threads.each(&:join)

        # Calculate statistics
        sorted_times = response_times.to_a.sort
        results[concurrent_users] = {
          avg: sorted_times.sum / sorted_times.size,
          p50: sorted_times[sorted_times.size / 2],
          p95: sorted_times[(sorted_times.size * 0.95).to_i],
          p99: sorted_times[(sorted_times.size * 0.99).to_i],
          max: sorted_times.last
        }
      end

      # Output results for analysis
      puts "\n\nResponse Time Analysis:"
      puts "Users | Avg    | P50    | P95    | P99    | Max"
      puts "------|--------|--------|--------|--------|--------"
      results.each do |users, stats|
        puts "#{users.to_s.rjust(5)} | #{format_time(stats[:avg])} | #{format_time(stats[:p50])} | " +
             "#{format_time(stats[:p95])} | #{format_time(stats[:p99])} | #{format_time(stats[:max])}"
      end

      # Verify acceptable performance
      expect(results[100][:p95]).to be < 0.5, "P95 response time too high at 100 users"
    end
  end

  private

  def format_time(seconds)
    "#{(seconds * 1000).round(1)}ms".rjust(6)
  end
end