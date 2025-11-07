#!/usr/bin/env ruby
# Diagnostic script to understand enum handling in production

puts "=== Thredded Moderation Enum Diagnostic ==="
puts "Ruby version: #{RUBY_VERSION}"
puts "Rails version: #{Rails.version}"
puts "Environment: #{Rails.env}"
puts

# Test 1: Check if Thredded models are loaded
puts "1. Model Loading Check:"
puts "   Thredded::Post defined? #{defined?(Thredded::Post) ? 'Yes' : 'No'}"
if defined?(Thredded::Post)
  puts "   Thredded::Post.moderation_states: #{Thredded::Post.moderation_states.inspect}"
end
puts

# Test 2: Test enum conversion with different input types
if defined?(Thredded::Post) && Thredded::Post.moderation_states
  puts "2. Enum Conversion Tests:"
  test_values = [
    :blocked,
    "blocked",
    "blocked".freeze,
    :blocked.to_s,
  ]

  test_values.each do |value|
    begin
      result = Thredded::Post.moderation_states[value.to_s]
      puts "   Input: #{value.inspect} (#{value.class})"
      puts "   .to_s: #{value.to_s.inspect}"
      puts "   Result: #{result.inspect}"
      puts "   Success: #{result ? 'Yes' : 'No'}"
    rescue => e
      puts "   Input: #{value.inspect} (#{value.class}) - ERROR: #{e.message}"
    end
    puts
  end
end

# Test 3: Test actual update_all behavior
if defined?(Thredded::Post) && Thredded::Post.moderation_states
  puts "3. Testing update_all with enum values:"

  # Create a test scope that won't actually update anything
  test_scope = Thredded::Post.where(id: -999999) # Non-existent ID

  [:blocked, "blocked"].each do |value|
    begin
      enum_value = Thredded::Post.moderation_states[value.to_s]
      puts "   Testing with #{value.inspect} -> enum: #{enum_value.inspect}"

      # Test the SQL generation without executing
      sql = test_scope.update_all(moderation_state: enum_value).to_sql rescue nil
      if sql
        puts "   Generated SQL: #{sql}"
      else
        # Actually try it if to_sql doesn't work
        count = test_scope.update_all(moderation_state: enum_value)
        puts "   Update succeeded (affected #{count} rows)"
      end
    rescue => e
      puts "   ERROR: #{e.class} - #{e.message}"
      puts "   Backtrace: #{e.backtrace.first(3).join("\n              ")}"
    end
    puts
  end
end

# Test 4: Check MySQL strict mode
puts "4. Database Configuration:"
begin
  result = ActiveRecord::Base.connection.select_one("SELECT @@sql_mode as mode")
  puts "   SQL Mode: #{result['mode']}"
  puts "   Strict mode enabled: #{result['mode'].include?('STRICT') ? 'Yes' : 'No'}"
rescue => e
  puts "   Could not check SQL mode: #{e.message}"
end
puts

# Test 5: Check for any monkey patches or overrides
puts "5. Method Definitions:"
if defined?(Thredded::Post)
  puts "   Post.update_all defined in: #{Thredded::Post.method(:update_all).source_location.inspect}"
  puts "   Post.moderation_states defined in: #{Thredded::Post.method(:moderation_states).source_location.inspect}"
end

puts "\n=== End of Diagnostic ==="