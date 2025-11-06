# frozen_string_literal: true

# Performance optimizations for Thredded moderation approve/block actions
# Addresses N+1 queries and inefficient bulk operations

Rails.application.config.after_initialize do
  if defined?(Thredded::ModeratePost)
    # Override the inefficient ModeratePost implementation
    Thredded::ModeratePost.module_eval do
      module_function

      # Optimized version of run! with better query performance
      def run!(post:, moderation_state:, moderator:)
        Rails.logger.info "[MODERATION OPTIMIZATION] Starting moderation action for post #{post.id}"
        start_time = Time.current

        Thredded::Post.transaction do
          # Create moderation record
          post_moderation_record = Thredded::PostModerationRecord.record!(
            moderator: moderator,
            post: post,
            previous_moderation_state: post.moderation_state,
            moderation_state: moderation_state,
          )

          # Update user detail if needed (only for pending users)
          if post.user_id && post.user_detail&.pending_moderation?
            update_without_timestamping!(post.user_detail, moderation_state: moderation_state)
          end

          # Check if this is the first post more efficiently
          # Instead of loading first_post, we check by created_at
          is_first_post = false
          if post.postable
            # Use a single query to check if this is the oldest post
            is_first_post = !post.postable.posts
                                 .where('created_at < ?', post.created_at)
                                 .exists?
          end

          if is_first_post
            Rails.logger.info "[MODERATION OPTIMIZATION] Post is first post of topic"
            update_without_timestamping!(post.postable, moderation_state: moderation_state)

            if moderation_state.to_sym == :blocked
              # Bulk update all other posts by this user in the topic
              # Instead of loading and updating each post individually
              other_posts_count = post.postable.posts
                                     .where(user_id: post.user_id)
                                     .where.not(id: post.id)
                                     .update_all(
                                       moderation_state: moderation_state,
                                       updated_at: Time.current
                                     )
              Rails.logger.info "[MODERATION OPTIMIZATION] Bulk updated #{other_posts_count} other posts"
            end
          end

          # Update the main post
          update_without_timestamping!(post, moderation_state: moderation_state)

          elapsed = Time.current - start_time
          Rails.logger.info "[MODERATION OPTIMIZATION] Completed moderation in #{elapsed}s"

          post_moderation_record
        end
      end

      # Keep the original update_without_timestamping! method
      def update_without_timestamping!(record, *attr)
        record_timestamps_was = record.record_timestamps
        begin
          record.record_timestamps = false
          record.update!(*attr)
        ensure
          record.record_timestamps = record_timestamps_was
        end
      end
    end
  end

  # Optimize the moderation controller to preload user_details
  if defined?(Thredded::ModerationController)
    Thredded::ModerationController.class_eval do
      private

      # Override to include user_detail in preloads
      def preload_posts_for_moderation(posts)
        posts.includes(:user, :messageboard, :postable)
             .joins("LEFT JOIN thredded_user_details ON thredded_user_details.user_id = thredded_posts.user_id")
             .preload(user: :thredded_user_detail)
      end

      # Override moderate_post action with better preloading
      def moderate_post
        moderation_state = params[:moderation_state].to_s
        return head(:bad_request) unless Thredded::Post.moderation_states.include?(moderation_state)

        # Preload associations to avoid N+1
        post = moderatable_posts
               .includes(:user, :postable, user: :thredded_user_detail)
               .find(params[:id].to_s)

        if post.moderation_state != moderation_state
          flash[:last_moderated_record_id] = Thredded::ModeratePost.run!(
            post: post,
            moderation_state: moderation_state,
            moderator: thredded_current_user,
          ).id
        else
          flash[:alert] = "Post was already #{moderation_state}:"
          flash[:last_moderated_record_id] =
            Thredded::PostModerationRecord.order_newest_first.find_by(post_id: post.id)&.id
        end
        redirect_back fallback_location: pending_moderation_path
      end
    end
  end

  # Add an index to improve first post checking if not exists
  if defined?(Thredded::Post) && ActiveRecord::Base.connection.table_exists?('thredded_posts')
    # Cache first post status to avoid repeated queries
    Thredded::Topic.class_eval do
      # Add a method to efficiently check if a post is first
      def first_post?(post)
        @first_post_id ||= posts.minimum(:id)
        post.id == @first_post_id
      end
    end

    # Use the cached method in Post
    Thredded::Post.class_eval do
      def is_first_post?
        postable&.first_post?(self)
      end
    end
  end

  Rails.logger.info "[THREDDED OPTIMIZATION] Moderation actions optimizations loaded"
end