#!/usr/bin/env ruby
# Script to profile moderation approve/block operations
# Run with: RAILS_ENV=production bundle exec rails runner scripts/profile_moderation_actions.rb

require 'benchmark'

puts "=== Thredded Moderation Actions Performance Profile ==="
puts "Environment: #{Rails.env}"
puts "Time: #{Time.current}"
puts

# Find a moderator user
moderator = User.joins(:thredded_user_detail).where(thredded_user_details: { moderation_state: 'moderator' }).first
unless moderator
  puts "ERROR: No moderator user found!"
  exit 1
end
puts "Using moderator: #{moderator.email}"

# Find some pending posts
pending_posts = Thredded::Post.where(moderation_state: 'pending_moderation').limit(5)
if pending_posts.empty?
  puts "No pending posts found to test with."
  exit 0
end

puts "\n=== Testing Moderation Performance ==="
puts "Found #{pending_posts.count} pending posts to test"

# Profile each step of the moderation process
pending_posts.each_with_index do |post, index|
  puts "\n--- Post #{index + 1} ---"
  puts "Post ID: #{post.id}"
  puts "User: #{post.user&.email || 'Unknown'}"
  puts "Topic: #{post.postable&.title || 'Unknown'}"

  # Measure total moderation time
  total_time = Benchmark.realtime do
    # Measure individual steps
    times = {}

    times[:load_user_detail] = Benchmark.realtime do
      post.user_detail if post.user_id
    end

    times[:load_postable] = Benchmark.realtime do
      post.postable
    end

    times[:check_first_post] = Benchmark.realtime do
      post.postable&.first_post
    end

    times[:transaction] = Benchmark.realtime do
      Thredded::Post.transaction do
        # Simulate the moderation record creation
        times[:create_record] = Benchmark.realtime do
          # Don't actually create it in profiling
          # Thredded::PostModerationRecord.record!(...)
        end

        # Check if this is first post
        if post.postable && post.postable.first_post == post
          times[:update_topic] = Benchmark.realtime do
            # Would update topic moderation state
          end

          # If blocking, count related posts
          times[:count_user_posts] = Benchmark.realtime do
            count = post.postable.posts.where(user_id: post.user.id).where.not(id: post.id).count
            puts "  Related posts by user: #{count}"
          end
        end
      end
    end

    puts "\nTiming breakdown:"
    times.each do |step, time|
      puts "  #{step}: #{(time * 1000).round(2)}ms"
    end
  end

  puts "Total time: #{(total_time * 1000).round(2)}ms"
end

# Check for missing includes
puts "\n=== Checking for N+1 Queries ==="
puts "Testing with logging enabled..."

original_logger = ActiveRecord::Base.logger
ActiveRecord::Base.logger = Logger.new(STDOUT)

sample_post = pending_posts.first
if sample_post
  queries = []

  # Capture queries
  ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    queries << event.payload[:sql] if event.payload[:sql] !~ /^(BEGIN|COMMIT|PRAGMA)/
  end

  # Simulate moderation
  post.user_detail if sample_post.user_id
  sample_post.postable
  sample_post.postable.first_post if sample_post.postable

  ActiveSupport::Notifications.unsubscribe "sql.active_record"

  puts "\nQueries executed: #{queries.size}"
  queries.each { |q| puts "  #{q[0..100]}..." }
end

ActiveRecord::Base.logger = original_logger

puts "\n=== Optimization Recommendations ==="
puts "1. Preload user_detail when loading posts for moderation"
puts "2. Avoid calling first_post which triggers expensive queries"
puts "3. Use bulk updates for blocking multiple posts"
puts "4. Consider caching first_post status on the post itself"
puts "5. Add indexes for user_id + postable_id queries"

puts "\nProfile complete."