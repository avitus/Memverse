#!/usr/bin/env ruby
# Script to diagnose moderation page performance issues
# Run with: RAILS_ENV=production bundle exec rails runner scripts/diagnose_moderation_performance.rb

puts "=== Thredded Moderation Page Performance Diagnosis ==="
puts "Environment: #{Rails.env}"
puts "Time: #{Time.current}"
puts

# 1. Check database statistics
puts "=== Database Statistics ==="
puts "Total posts: #{Thredded::Post.count}"
puts "Posts by moderation state:"
Thredded::Post.group(:moderation_state).count.each do |state, count|
  puts "  #{state || 'nil'}: #{count}"
end

puts "\nTotal topics: #{Thredded::Topic.count}"
puts "Total messageboards: #{Thredded::Messageboard.count}"
puts "Total users: #{User.count}"
puts "Total user details: #{Thredded::UserDetail.count}"

# 2. Check indexes on thredded_posts
puts "\n=== Indexes on thredded_posts ==="
connection = ActiveRecord::Base.connection
indexes = connection.indexes('thredded_posts')
if indexes.empty?
  puts "WARNING: No indexes found on thredded_posts table!"
else
  indexes.each do |index|
    puts "  #{index.name}: #{index.columns.join(', ')}"
  end
end

# 3. Analyze query performance
puts "\n=== Query Performance Analysis ==="

# Test basic pending moderation query
puts "\n1. Basic pending moderation query:"
start_time = Time.current
count = Thredded::Post.where(moderation_state: 'pending_moderation').count
puts "   Count: #{count} posts"
puts "   Time: #{Time.current - start_time}s"

# Test with includes
puts "\n2. Query with includes:"
start_time = Time.current
posts = Thredded::Post
  .where(moderation_state: 'pending_moderation')
  .includes(:user, :messageboard, :postable)
  .limit(25)
posts.to_a  # Force loading
puts "   Time: #{Time.current - start_time}s"

# Test with preload_first_topic_post (if method exists)
if Thredded::Post.respond_to?(:preload_first_topic_post)
  puts "\n3. Query with preload_first_topic_post:"
  start_time = Time.current
  posts = Thredded::Post
    .where(moderation_state: 'pending_moderation')
    .includes(:user, :messageboard, :postable)
    .limit(25)
    .preload_first_topic_post
  posts.to_a  # Force loading
  puts "   Time: #{Time.current - start_time}s"
  puts "   WARNING: This method may be causing performance issues!"
end

# 4. Check for missing associations
puts "\n=== Association Checks ==="
sample_post = Thredded::Post.where(moderation_state: 'pending_moderation').first
if sample_post
  puts "Sample post associations:"
  puts "  Has user? #{sample_post.user.present?}"
  puts "  Has messageboard? #{sample_post.messageboard.present?}"
  puts "  Has postable? #{sample_post.postable.present?}"
  puts "  Postable type: #{sample_post.postable_type}" if sample_post.respond_to?(:postable_type)
end

# 5. Check for potential N+1 queries
puts "\n=== N+1 Query Detection ==="
puts "Loading first 10 pending posts with associations..."
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::DEBUG

posts = Thredded::Post
  .where(moderation_state: 'pending_moderation')
  .includes(:user, :messageboard, :postable)
  .limit(10)

posts.each do |post|
  # These should not generate additional queries
  post.user&.name
  post.messageboard&.name
  post.postable&.title if post.postable&.respond_to?(:title)
end

ActiveRecord::Base.logger = Rails.logger

# 6. Check pagination settings
puts "\n=== Pagination Settings ==="
puts "Kaminari default per page: #{Kaminari.config.default_per_page}"
puts "Thredded posts per page: #{Thredded.posts_per_page}"

# 7. Memory usage check
puts "\n=== Memory Usage ==="
if defined?(GetProcessMem)
  mem = GetProcessMem.new
  puts "Current memory: #{mem.mb.round(2)} MB"
else
  puts "GetProcessMem not available"
end

puts "\n=== Recommendations ==="
puts "1. Ensure all indexes from the migration are present"
puts "2. Consider reducing posts per page if set too high"
puts "3. Monitor for N+1 queries in production logs"
puts "4. Check if preload_first_topic_post is being called"
puts "5. Consider caching moderation counts"

puts "\nDiagnosis complete."