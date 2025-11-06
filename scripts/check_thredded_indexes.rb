#!/usr/bin/env ruby
# Script to check existing indexes on thredded_posts table
# Run with: bundle exec rails runner scripts/check_thredded_indexes.rb

puts "=== Checking Thredded Posts Indexes ==="
puts "Environment: #{Rails.env}"
puts

# Get existing indexes
existing_indexes = ActiveRecord::Base.connection.indexes('thredded_posts')

if existing_indexes.empty?
  puts "❌ NO INDEXES found on thredded_posts table!"
else
  puts "✓ Found #{existing_indexes.count} indexes:"
  existing_indexes.each do |index|
    puts "  - #{index.name}: #{index.columns.join(', ')}"
  end
end

# Check for expected indexes
expected_indexes = [
  'index_thredded_posts_on_moderation_state',
  'index_thredded_posts_on_user_id',
  'index_thredded_posts_on_postable_id',
  'index_thredded_posts_on_messageboard_id',
  'index_thredded_posts_for_display',
  'index_thredded_posts_on_postable_id_and_created_at'
]

puts "\n=== Missing Indexes ==="
existing_index_names = existing_indexes.map(&:name)
missing_indexes = expected_indexes - existing_index_names

if missing_indexes.empty?
  puts "✓ All expected indexes are present!"
else
  puts "❌ Missing indexes:"
  missing_indexes.each do |index_name|
    puts "  - #{index_name}"
  end
end

# Check posts count and moderation states
puts "\n=== Table Statistics ==="
puts "Total posts: #{Thredded::Post.count}"
puts "Posts by moderation state:"
Thredded::Post.group(:moderation_state).count.each do |state, count|
  puts "  - #{state || 'nil'}: #{count}"
end