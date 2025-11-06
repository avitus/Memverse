# frozen_string_literal: true

# Add caching to Thredded moderation page for better performance
# The moderation page data doesn't change frequently, so short-term caching can help significantly

Rails.application.config.after_initialize do
  if defined?(Thredded::ModerationController) && Rails.application.config.action_controller.perform_caching
    Thredded::ModerationController.class_eval do
      # Add caching to the expensive pending action
      around_action :cache_pending_moderation, only: :pending

      private

      def cache_pending_moderation
        # Create a cache key based on:
        # - Current user ID (different moderators might see different content)
        # - Page number
        # - Count of pending posts (to invalidate when new posts arrive)
        # - Last moderated record (if any)

        cache_key_parts = [
          'thredded_moderation_pending',
          thredded_current_user.id,
          params[:page] || 1,
          Thredded::Post.where(moderation_state: 'pending_moderation').count,
          Thredded::Post.where(moderation_state: 'pending_moderation').maximum(:updated_at)&.to_i
        ]

        cache_key = cache_key_parts.compact.join('-')

        # Cache for 1 minute - short enough to not miss new posts, long enough to help performance
        Rails.cache.fetch(cache_key, expires_in: 1.minute) do
          Rails.logger.info "[MODERATION CACHE] Cache miss for key: #{cache_key}"
          yield
        end
      end
    end

    # Also add a method to clear moderation cache when posts are moderated
    Thredded::ModeratePost.class_eval do
      set_callback :save, :after, :clear_moderation_cache

      private

      def clear_moderation_cache
        # Clear all moderation pending caches
        Rails.cache.delete_matched('thredded_moderation_pending-*')
        Rails.logger.info "[MODERATION CACHE] Cleared moderation cache after post moderation"
      rescue => e
        # Some cache stores don't support delete_matched
        Rails.logger.warn "[MODERATION CACHE] Could not clear cache: #{e.message}"
      end
    end
  end
end