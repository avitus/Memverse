#!/usr/bin/env ruby

# Run with: ruby test/performance/benchmark_quiz_sse.rb

require 'benchmark'
require 'net/http'
require 'json'
require 'optparse'

# Load concurrent-ruby if available
begin
  require 'concurrent'
rescue LoadError
  # Define minimal atomic classes if concurrent-ruby is not available
  module Concurrent
    class AtomicFixnum
      def initialize(value = 0)
        @value = value
        @mutex = Mutex.new
      end

      def increment
        @mutex.synchronize { @value += 1 }
      end

      def decrement
        @mutex.synchronize { @value -= 1 }
      end

      def add(n)
        @mutex.synchronize { @value += n }
      end

      def value
        @mutex.synchronize { @value }
      end
    end

    class Array < ::Array
      def initialize
        super
        @mutex = Mutex.new
      end

      def <<(item)
        @mutex.synchronize { super }
      end

      def to_a
        @mutex.synchronize { self.dup }
      end
    end
  end
end

class QuizSSEBenchmark
  attr_reader :options

  def initialize(options = {})
    @options = {
      host: 'localhost',
      port: 3000,
      quiz_id: 1,
      concurrent_users: 100,
      duration: 300, # 5 minutes
      warmup_time: 10,
      report_interval: 30
    }.merge(options)

    @metrics = {
      connections: Concurrent::AtomicFixnum.new(0),
      messages_received: Concurrent::AtomicFixnum.new(0),
      errors: Concurrent::AtomicFixnum.new(0),
      bytes_received: Concurrent::AtomicFixnum.new(0),
      latencies: Concurrent::Array.new
    }
  end

  def run
    puts "Quiz SSE Performance Benchmark"
    puts "=" * 50
    puts "Target: http://#{options[:host]}:#{options[:port]}"
    puts "Quiz ID: #{options[:quiz_id]}"
    puts "Concurrent users: #{options[:concurrent_users]}"
    puts "Duration: #{options[:duration]}s"
    puts "=" * 50

    warmup
    benchmark
    report_results
  end

  private

  def warmup
    print "\nWarming up for #{options[:warmup_time]}s..."

    # Create a few connections to warm up the server
    warmup_threads = []
    5.times do
      warmup_threads << Thread.new do
        make_sse_connection(options[:warmup_time])
      end
    end

    warmup_threads.each(&:join)
    puts " done!"
  end

  def benchmark
    puts "\nStarting benchmark..."
    start_time = Time.now
    threads = []

    # Start monitoring thread
    monitor_thread = Thread.new do
      monitor_performance(start_time)
    end

    # Gradually ramp up connections
    options[:concurrent_users].times do |i|
      threads << Thread.new do
        user_start = Time.now
        make_sse_connection(options[:duration] - (user_start - start_time))
      end

      # Ramp up over 10 seconds to avoid thundering herd
      sleep(10.0 / options[:concurrent_users]) if i < options[:concurrent_users] - 1
    end

    # Wait for all connections to finish
    threads.each(&:join)
    monitor_thread.kill

    puts "\nBenchmark completed!"
  end

  def make_sse_connection(duration)
    connection_start = Time.now
    uri = URI("http://#{options[:host]}:#{options[:port]}/live_quiz/events?id=#{options[:quiz_id]}")

    begin
      Net::HTTP.start(uri.host, uri.port, read_timeout: duration + 10) do |http|
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = 'text/event-stream'
        request['Cache-Control'] = 'no-cache'

        http.request(request) do |response|
          if response.code == '200'
            @metrics[:connections].increment

            response.read_body do |chunk|
              @metrics[:bytes_received].add(chunk.bytesize)

              # Parse SSE events
              if chunk.include?('event: quiz-state')
                message_received = Time.now
                @metrics[:messages_received].increment

                # Extract timestamp if available
                if match = chunk.match(/timestamp["\s:]+(\S+)/)
                  begin
                    sent_time = Time.parse(match[1])
                    latency = (message_received - sent_time) * 1000 # Convert to ms
                    @metrics[:latencies] << latency if latency > 0 && latency < 10000
                  rescue
                    # Ignore parsing errors
                  end
                end
              end

              # Stop reading after duration
              break if Time.now - connection_start > duration
            end
          else
            @metrics[:errors].increment
          end
        end
      end
    rescue => e
      @metrics[:errors].increment
      puts "Connection error: #{e.class.name}" if options[:verbose]
    ensure
      @metrics[:connections].decrement if @metrics[:connections].value > 0
    end
  end

  def monitor_performance(start_time)
    last_messages = 0
    last_bytes = 0
    last_report = Time.now

    loop do
      sleep(options[:report_interval])

      current_time = Time.now
      elapsed = current_time - start_time
      report_elapsed = current_time - last_report

      current_messages = @metrics[:messages_received].value
      current_bytes = @metrics[:bytes_received].value

      messages_per_sec = (current_messages - last_messages) / report_elapsed
      bytes_per_sec = (current_bytes - last_bytes) / report_elapsed

      puts "\n[#{elapsed.round}s] Active connections: #{@metrics[:connections].value} | " \
           "Messages/sec: #{messages_per_sec.round(1)} | " \
           "KB/sec: #{(bytes_per_sec / 1024).round(1)} | " \
           "Errors: #{@metrics[:errors].value}"

      last_messages = current_messages
      last_bytes = current_bytes
      last_report = current_time

      break if elapsed > options[:duration]
    end
  end

  def report_results
    puts "\n" + "=" * 50
    puts "BENCHMARK RESULTS"
    puts "=" * 50

    total_connections = options[:concurrent_users]
    total_messages = @metrics[:messages_received].value
    total_bytes = @metrics[:bytes_received].value
    total_errors = @metrics[:errors].value

    puts "\nConnections:"
    puts "  Total attempted: #{total_connections}"
    puts "  Errors: #{total_errors} (#{(total_errors.to_f / total_connections * 100).round(1)}%)"

    puts "\nMessages:"
    puts "  Total received: #{total_messages}"
    puts "  Per connection: #{(total_messages.to_f / total_connections).round(1)}"
    puts "  Per second: #{(total_messages.to_f / options[:duration]).round(1)}"

    puts "\nData Transfer:"
    puts "  Total: #{(total_bytes.to_f / 1024 / 1024).round(2)} MB"
    puts "  Per connection: #{(total_bytes.to_f / total_connections / 1024).round(1)} KB"
    puts "  Throughput: #{(total_bytes.to_f / options[:duration] / 1024).round(1)} KB/s"

    if @metrics[:latencies].any?
      latencies = @metrics[:latencies].to_a.sort
      puts "\nLatency (ms):"
      puts "  Min: #{latencies.first.round(1)}"
      puts "  Avg: #{(latencies.sum / latencies.size).round(1)}"
      puts "  P50: #{percentile(latencies, 0.5).round(1)}"
      puts "  P95: #{percentile(latencies, 0.95).round(1)}"
      puts "  P99: #{percentile(latencies, 0.99).round(1)}"
      puts "  Max: #{latencies.last.round(1)}"
    end

    puts "\nSystem Impact:"
    puts "  Error rate: #{(total_errors.to_f / total_connections * 100).round(2)}%"
    puts "  Success rate: #{((total_connections - total_errors).to_f / total_connections * 100).round(2)}%"

    save_report if options[:output]
  end

  def percentile(array, percentile)
    array[(array.size * percentile).to_i]
  end

  def save_report
    report = {
      timestamp: Time.now.iso8601,
      options: options,
      results: {
        connections: {
          attempted: options[:concurrent_users],
          errors: @metrics[:errors].value
        },
        messages: {
          total: @metrics[:messages_received].value,
          per_second: @metrics[:messages_received].value.to_f / options[:duration]
        },
        data_transfer: {
          total_bytes: @metrics[:bytes_received].value,
          throughput_kbps: @metrics[:bytes_received].value.to_f / options[:duration] / 1024
        },
        latency_ms: calculate_latency_stats
      }
    }

    File.write(options[:output], JSON.pretty_generate(report))
    puts "\nReport saved to: #{options[:output]}"
  end

  def calculate_latency_stats
    latencies = @metrics[:latencies].to_a.sort
    return {} if latencies.empty?

    {
      min: latencies.first.round(1),
      avg: (latencies.sum / latencies.size).round(1),
      p50: percentile(latencies, 0.5).round(1),
      p95: percentile(latencies, 0.95).round(1),
      p99: percentile(latencies, 0.99).round(1),
      max: latencies.last.round(1),
      count: latencies.size
    }
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: benchmark_quiz_sse.rb [options]"

  opts.on("-h", "--host HOST", "Server host (default: localhost)") do |h|
    options[:host] = h
  end

  opts.on("-p", "--port PORT", Integer, "Server port (default: 3000)") do |p|
    options[:port] = p
  end

  opts.on("-q", "--quiz-id ID", Integer, "Quiz ID (default: 1)") do |q|
    options[:quiz_id] = q
  end

  opts.on("-u", "--users COUNT", Integer, "Concurrent users (default: 100)") do |u|
    options[:concurrent_users] = u
  end

  opts.on("-d", "--duration SECONDS", Integer, "Test duration in seconds (default: 300)") do |d|
    options[:duration] = d
  end

  opts.on("-o", "--output FILE", "Save results to JSON file") do |o|
    options[:output] = o
  end

  opts.on("-v", "--verbose", "Verbose output") do
    options[:verbose] = true
  end

  opts.on("--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Run benchmark
benchmark = QuizSSEBenchmark.new(options)
benchmark.run