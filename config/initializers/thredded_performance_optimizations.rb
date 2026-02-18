# frozen_string_literal: true

# Performance optimizations for Thredded forum.
#
# 1. preload_first_topic_post no-op: The default scope in Thredded::PostCommon
#    runs a MAX() subquery per topic, producing O(N) subqueries on the moderation
#    page. Since first-post data is not needed for moderation display, we replace
#    it with a no-op.
#
# 2. ModeratePost.run! bulk blocking: When blocking the first post of a topic,
#    the gem loops through all other posts by that user with individual update!
#    calls, each triggering expensive after_commit callbacks (update_post_counts!,
#    update_unread_posts_count, auto_follow_and_notify). We replace the loop with
#    a single update_all, which skips callbacks entirely.
#
# 3. moderate_post controller preloading: The default controller loads the post
#    without eager-loading associations, causing N+1 queries when ModeratePost
#    accesses user, postable, and user_detail.

Rails.application.config.after_initialize do
  # 1. Disable preload_first_topic_post (O(N) MAX subqueries)
  if defined?(Thredded::PostCommon)
    module Thredded
      module PostCommon
        module ClassMethods
          def preload_first_topic_post
            all
          end
        end
      end
    end
  end

  # 2. Optimize ModeratePost.run! to use bulk update for blocking
  if defined?(Thredded::ModeratePost)
    Thredded::ModeratePost.module_eval do
      module_function

      def run!(post:, moderation_state:, moderator:)
        state_value = moderation_state.to_s

        Thredded::Post.transaction do
          post_moderation_record = Thredded::PostModerationRecord.record!(
            moderator: moderator,
            post: post,
            previous_moderation_state: post.moderation_state,
            moderation_state: state_value,
          )

          if post.user_id && post.user_detail&.pending_moderation?
            update_without_timestamping!(post.user_detail, moderation_state: state_value)
          end

          # Use EXISTS check instead of loading the first post record
          is_first_post = post.postable &&
            !post.postable.posts.where('created_at < ?', post.created_at).exists?

          if is_first_post
            update_without_timestamping!(post.postable, moderation_state: state_value)

            if state_value == 'blocked'
              # Bulk update all other posts by this user in the topic.
              # Uses update_all to skip after_commit callbacks that would
              # otherwise trigger expensive update_post_counts! per post.
              enum_value = Thredded::Post.moderation_states[state_value]
              post.postable.posts
                .where(user_id: post.user_id)
                .where.not(id: post.id)
                .update_all(moderation_state: enum_value, updated_at: Time.current)
            end
          end

          update_without_timestamping!(post, moderation_state: state_value)
          post_moderation_record
        end
      end

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

  # 3. Preload associations in moderate_post controller action
  if defined?(Thredded::ModerationController)
    Thredded::ModerationController.class_eval do
      def moderate_post
        moderation_state = params[:moderation_state].to_s
        return head(:bad_request) unless Thredded::Post.moderation_states.include?(moderation_state)

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
end
