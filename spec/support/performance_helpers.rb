# Helper methods for performance and chaos testing
module PerformanceHelpers
  # Measure memory usage of a block
  def measure_memory(&block)
    initial_memory = GetProcessMem.new.mb
    result = block.call
    final_memory = GetProcessMem.new.mb

    {
      result: result,
      initial_memory: initial_memory,
      final_memory: final_memory,
      memory_delta: final_memory - initial_memory
    }
  end

  # Measure execution time with statistics
  def measure_time_with_stats(iterations: 100, &block)
    times = []

    iterations.times do
      start_time = Time.current
      block.call
      times << (Time.current - start_time)
    end

    sorted_times = times.sort

    {
      count: iterations,
      total: times.sum,
      avg: times.sum / times.size,
      min: sorted_times.first,
      max: sorted_times.last,
      p50: percentile(sorted_times, 0.5),
      p95: percentile(sorted_times, 0.95),
      p99: percentile(sorted_times, 0.99)
    }
  end

  # Calculate percentile from sorted array
  def percentile(sorted_array, p)
    return 0 if sorted_array.empty?
    k = (sorted_array.size * p).ceil - 1
    sorted_array[k]
  end

  # Simulate network conditions
  def with_simulated_latency(delay_ms: 100, &block)
    original_method = Redis.current.method(:publish)

    allow(Redis.current).to receive(:publish) do |*args|
      sleep(delay_ms / 1000.0)
      original_method.call(*args)
    end

    block.call
  ensure
    allow(Redis.current).to receive(:publish).and_call_original
  end

  # Create concurrent users efficiently
  def create_concurrent_users(count)
    users = []

    count.times do |i|
      users << FactoryBot.create(:user,
        email: "loadtest#{i}@example.com",
        login: "loadtest#{i}",
        name: "Load Test User #{i}"
      )
    end

    users
  end

  # Monitor Redis connections
  def monitor_redis_connections(&block)
    connection_info = []

    monitoring_thread = Thread.new do
      loop do
        info = Redis.current.info
        connection_info << {
          time: Time.current,
          connected_clients: info['connected_clients'],
          blocked_clients: info['blocked_clients']
        }
        sleep 1
      end
    end

    result = block.call

    monitoring_thread.kill

    {
      result: result,
      redis_stats: connection_info
    }
  end

  # Gradually increase load
  def ramp_up_load(initial: 10, final: 100, duration: 60, &block)
    threads = []
    step_duration = duration.to_f / (final - initial)

    initial.upto(final) do |count|
      threads << Thread.new { block.call(count) }
      sleep(step_duration)
    end

    threads.each(&:join)
  end

  # Format time in human-readable format
  def format_duration(seconds)
    if seconds < 1
      "#{(seconds * 1000).round(1)}ms"
    elsif seconds < 60
      "#{seconds.round(1)}s"
    else
      minutes = (seconds / 60).to_i
      secs = (seconds % 60).to_i
      "#{minutes}m #{secs}s"
    end
  end

  # Generate load test report
  def generate_performance_report(test_name, results)
    report = []
    report << "\n" + "=" * 60
    report << "Performance Report: #{test_name}"
    report << "=" * 60
    report << "Generated at: #{Time.current}"
    report << ""

    if results[:timing]
      report << "Timing Statistics:"
      report << "  Average: #{format_duration(results[:timing][:avg])}"
      report << "  Min: #{format_duration(results[:timing][:min])}"
      report << "  Max: #{format_duration(results[:timing][:max])}"
      report << "  P50: #{format_duration(results[:timing][:p50])}"
      report << "  P95: #{format_duration(results[:timing][:p95])}"
      report << "  P99: #{format_duration(results[:timing][:p99])}"
    end

    if results[:memory]
      report << ""
      report << "Memory Usage:"
      report << "  Initial: #{results[:memory][:initial].round(2)} MB"
      report << "  Final: #{results[:memory][:final].round(2)} MB"
      report << "  Delta: #{results[:memory][:delta].round(2)} MB"
    end

    if results[:errors]
      report << ""
      report << "Errors:"
      report << "  Total: #{results[:errors][:count]}"
      report << "  Rate: #{results[:errors][:rate]}%"
    end

    report << "=" * 60

    puts report.join("\n")

    # Optionally save to file
    if ENV['SAVE_PERFORMANCE_REPORTS']
      filename = "tmp/performance_#{test_name.downcase.gsub(/\s+/, '_')}_#{Time.current.to_i}.txt"
      File.write(filename, report.join("\n"))
      puts "Report saved to: #{filename}"
    end
  end
end

# Include in RSpec configuration
RSpec.configure do |config|
  config.include PerformanceHelpers, type: :request
end