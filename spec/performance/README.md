# Performance and Chaos Engineering Tests

This directory contains comprehensive performance, stability, and chaos engineering tests for the Live Quiz SSE (Server-Sent Events) functionality.

## Test Categories

### 1. Load Testing (`live_quiz_load_spec.rb`)
Tests the system's ability to handle high concurrent loads:
- **100 concurrent SSE connections**: Verifies the system can handle many simultaneous users
- **State broadcast performance**: Tests efficient message delivery to all connected users
- **Graceful degradation**: Ensures system remains stable under extreme load (1000+ connections)
- **Resource monitoring**: Tracks memory usage and Redis connection pool utilization

### 2. Stability Testing (`../stability/live_quiz_stability_spec.rb`)
Tests long-term system stability:
- **2-hour connection stability**: Verifies SSE connections remain stable over extended periods
- **Repeated quiz cycles**: Tests 10 back-to-back quiz sessions for memory leaks
- **Memory stability**: Monitors memory usage patterns over time
- **Redis connection stability**: Ensures Redis pub/sub remains stable under sustained load

### 3. Chaos Engineering (`../chaos/live_quiz_chaos_spec.rb`)
Tests system resilience to various failure scenarios:
- **Clock skew**: Handles client/server time differences and DST transitions
- **Redis failures**: Graceful degradation during connection failures and restarts
- **Network issues**: Handles high latency and packet loss
- **Race conditions**: Manages concurrent modifications safely
- **Resource exhaustion**: Handles excessive registrations and malformed data
- **Byzantine failures**: Recovers from corrupted data and partial failures

### 4. Benchmark Tool (`../../test/performance/benchmark_quiz_sse.rb`)
A standalone benchmarking tool for SSE performance:
- Configurable concurrent users and duration
- Real-time performance monitoring
- Detailed latency percentiles
- JSON report generation

## Running the Tests

### Prerequisites
```bash
# Install required gems
bundle install

# Ensure Redis is running
redis-server

# Start the Rails server (for benchmark tool)
rails server
```

### Running Individual Test Suites

#### Load Tests
```bash
# Run with LOAD_TEST environment variable
LOAD_TEST=true bundle exec rspec spec/performance/live_quiz_load_spec.rb

# Run specific test
LOAD_TEST=true bundle exec rspec spec/performance/live_quiz_load_spec.rb -e "handles 100 concurrent SSE connections"
```

#### Stability Tests
```bash
# Full stability tests (takes hours)
STABILITY_TEST=true bundle exec rspec spec/stability/live_quiz_stability_spec.rb

# Quick stability test (reduced duration)
STABILITY_TEST=true QUICK_TEST=true bundle exec rspec spec/stability/live_quiz_stability_spec.rb
```

#### Chaos Tests
```bash
# Run all chaos tests
bundle exec rspec spec/chaos/live_quiz_chaos_spec.rb

# Run specific chaos scenario
bundle exec rspec spec/chaos/live_quiz_chaos_spec.rb -e "handles Redis connection failure"
```

### Running the Benchmark Tool
```bash
# Basic benchmark (100 users for 5 minutes)
ruby test/performance/benchmark_quiz_sse.rb

# Custom configuration
ruby test/performance/benchmark_quiz_sse.rb -u 200 -d 600 -o results.json

# All options
ruby test/performance/benchmark_quiz_sse.rb --help
```

## Performance Targets

Based on the tests, the system should meet these performance criteria:

### Connection Performance
- Average connection time: < 100ms
- Maximum connection time: < 500ms
- 100 concurrent connections established: < 10s

### Message Latency
- Average broadcast latency: < 50ms
- P95 response time (100 users): < 500ms

### Stability
- Memory growth rate: < 50MB/hour
- Connection stability: 0 disconnections over 2 hours
- Quiz cycle variance: < 5 seconds

### Resilience
- Success rate under extreme load (1000 connections): > 80%
- Recovery from Redis restart: Automatic
- Clock skew tolerance: ±5 minutes

## Monitoring During Tests

While running performance tests, monitor:

1. **Application logs**:
   ```bash
   tail -f log/development.log
   ```

2. **Redis activity**:
   ```bash
   redis-cli monitor
   ```

3. **System resources**:
   ```bash
   top -p $(pgrep -f "rails server")
   ```

## Interpreting Results

### Load Test Results
- Check for connection errors and timeouts
- Verify response time percentiles meet targets
- Monitor memory usage trends

### Stability Test Results
- Look for memory leaks (increasing memory over time)
- Check for accumulated errors or degraded performance
- Verify consistent quiz cycle times

### Chaos Test Results
- Ensure graceful degradation (no crashes)
- Verify automatic recovery mechanisms
- Check data consistency after failures

## CI Integration

To run these tests in CI:

```yaml
# Example CircleCI configuration
performance_tests:
  docker:
    - image: cimg/ruby:3.2.6
    - image: redis:6-alpine
  steps:
    - checkout
    - run:
        name: Run load tests
        command: LOAD_TEST=true bundle exec rspec spec/performance/
        no_output_timeout: 30m
```

## Troubleshooting

### Common Issues

1. **"Too many open files" error**:
   ```bash
   # Increase file descriptor limit
   ulimit -n 4096
   ```

2. **Redis connection pool exhausted**:
   - Check Redis max clients configuration
   - Ensure proper connection cleanup in tests

3. **Memory errors during tests**:
   - Reduce concurrent users
   - Run tests with more available memory

### Debug Mode

For detailed debugging during tests:
```bash
DEBUG=true LOAD_TEST=true bundle exec rspec spec/performance/live_quiz_load_spec.rb
```