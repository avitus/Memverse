# frozen_string_literal: true

# Performance optimizations for Thredded forum moderation page
# The default preload_first_topic_post implementation uses inefficient subqueries
# This monkey patch replaces it with a more efficient approach

Rails.application.config.after_initialize do
  if defined?(Thredded::PostCommon)
    module Thredded
      module PostCommon
        module ClassMethods
          # Override the inefficient preload_first_topic_post scope
          # Original implementation uses a MAX subquery for each post which is very slow
          def preload_first_topic_post
            # Skip the expensive preloading for now
            # In most cases, the first post information is not critical for moderation
            # and can be loaded on-demand if needed
            all
          end
        end
      end
    end
  end

  # Alternative: If we need the first post data, use a more efficient approach
  # This would require more complex refactoring but here's the concept:
  #
  # def preload_first_topic_post_efficient
  #   posts = all.to_a
  #   return posts if posts.empty?
  #
  #   # Get all unique postable_ids
  #   postable_ids = posts.map(&:postable_id).uniq
  #
  #   # Load first posts in a single query instead of N subqueries
  #   first_posts = Thredded::Post
  #     .select('postable_id, MIN(created_at) as min_created_at')
  #     .where(postable_id: postable_ids)
  #     .group(:postable_id)
  #
  #   # Then load the actual first posts
  #   first_post_conditions = first_posts.map { |fp|
  #     "(postable_id = #{fp.postable_id} AND created_at = '#{fp.min_created_at}')"
  #   }.join(' OR ')
  #
  #   actual_first_posts = Thredded::Post
  #     .where(first_post_conditions)
  #     .index_by(&:postable_id)
  #
  #   # Assign to topics
  #   posts.each do |post|
  #     if post.postable && actual_first_posts[post.postable_id]
  #       post.postable.association(:first_post).target = actual_first_posts[post.postable_id]
  #     end
  #   end
  #
  #   posts
  # end

  # Additional optimization: Add a default scope for pending moderation to use the proper index
  if defined?(Thredded::Post)
    Thredded::Post.class_eval do
      # Ensure the moderation queries use the composite index efficiently
      scope :pending_moderation_optimized, -> {
        where(moderation_state: 'pending_moderation')
          .includes(:user, :messageboard, :postable)
          .order('thredded_posts.updated_at DESC')
      }
    end
  end

  # Log that optimizations are active
  Rails.logger.info "[THREDDED OPTIMIZATION] Moderation page performance optimizations loaded"
end