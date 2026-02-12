# Quiz State Machine Test Suite

This document describes the comprehensive unit tests created for the quiz state machine.

## Test Files Created

### 1. `/spec/controllers/live_quiz_state_machine_spec.rb`
Tests for the controller-level state machine logic.

**Coverage:**
- **State Transitions**: Tests all valid state transitions (none → waiting → preparing → ready → running → finished)
- **Concurrent Requests**: Verifies handling of multiple simultaneous state requests without race conditions
- **Timing Windows**: Tests edge cases around the 5-second transition boundary
- **State Persistence**: Tests recovery from Redis failures and reconnections
- **Performance**: Ensures rapid state checks complete efficiently

**Key Test Scenarios:**
- Validates that states follow the correct progression
- Tests boundary conditions (exact 5-second timing, past start times)
- Handles microsecond time precision
- Degrades gracefully when Redis is unavailable
- Maintains consistency under high concurrency

### 2. `/spec/services/quiz_state_manager_spec.rb`
Tests for atomic state management and race condition prevention.

**Coverage:**
- **Atomic Transitions**: Tests that state changes are atomic and consistent
- **Lock Management**: Verifies distributed locking prevents duplicate quiz execution
- **State Rollback**: Tests recovery mechanisms for failed operations
- **Deadlock Prevention**: Ensures proper lock ordering and timeout handling

**Key Test Scenarios:**
- Uses Redis locks to prevent concurrent quiz execution
- Implements optimistic locking patterns
- Provides rollback mechanisms for failed state transitions
- Handles lock timeouts and automatic recovery
- Maintains state machine invariants

### 3. `/spec/workers/knowledge_quiz_state_spec.rb`
Tests for the worker's state publishing and synchronization.

**Coverage:**
- **State Publishing**: Tests reliable publishing of state changes via Redis pub/sub
- **Ordered Delivery**: Ensures states are delivered in the correct sequence
- **Idempotency**: Verifies duplicate state changes are handled gracefully
- **State Recovery**: Tests recovery from interrupted transitions

**Key Test Scenarios:**
- Publishes state transitions with timestamps
- Includes previous state in transitions for client handling
- Prevents duplicate quiz execution within time windows
- Coordinates state with controller state machine
- Handles publish failures without blocking quiz execution

## Running the Tests

Run individual test files:
```bash
bundle exec rspec spec/controllers/live_quiz_state_machine_spec.rb
bundle exec rspec spec/services/quiz_state_manager_spec.rb
bundle exec rspec spec/workers/knowledge_quiz_state_spec.rb
```

Run all state machine tests:
```bash
bundle exec rspec spec/controllers/live_quiz_state_machine_spec.rb spec/services/quiz_state_manager_spec.rb spec/workers/knowledge_quiz_state_spec.rb
```

## Test Patterns Used

### 1. Thread Safety Testing
```ruby
threads = 10.times.map do
  Thread.new do
    # Concurrent operation
  end
end
threads.each(&:join)
```

### 2. Redis Synchronization
```ruby
wait_for_redis_sync do
  session = QuizSession.new(quiz_id)
  session.get_quiz_status == expected_status
end
```

### 3. State Transition Validation
```ruby
states.each_cons(2) do |prev_state, next_state|
  valid_transition = validate_transition(prev_state, next_state)
  expect(valid_transition).to be_truthy
end
```

### 4. Time-based Testing
```ruby
Timeout.timeout(3) do
  while states_captured.size < 5
    state = controller.send(:calculate_quiz_state, quiz)
    states_captured << state[:state]
    sleep 0.3
  end
end
```

## Test Helpers

The tests use the `LiveQuizHelpers` module for common setup:
- `setup_quiz_session_with_sync`: Sets up quiz session with Redis synchronization
- `wait_for_redis_sync`: Waits for Redis data to be visible across processes
- Thread-safe controller instantiation for concurrent testing

## Known Issues and Limitations

1. Some worker tests require actual quiz execution which takes time
2. Redis mocking is limited for pub/sub functionality
3. Timing-sensitive tests may occasionally fail under heavy system load

## Future Improvements

1. Add property-based testing for state transitions
2. Implement chaos testing for Redis failures
3. Add performance benchmarks for state calculations
4. Create integration tests for full state machine flow