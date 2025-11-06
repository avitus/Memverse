# frozen_string_literal: true

# Override Thredded's moderation controller to add performance logging and optimizations

Rails.application.config.after_initialize do
  if defined?(Thredded::ModerationController)
    Thredded::ModerationController.class_eval do
      # Override the pending action with performance monitoring
      def pending
        start_time = Time.current
        query_times = {}

        # Log the start
        Rails.logger.info "[MODERATION TIMING] Started loading pending moderation page"

        # Time the messageboard query
        query_start = Time.current
        messageboards = moderatable_messageboards
        query_times[:messageboards] = Time.current - query_start
        Rails.logger.info "[MODERATION TIMING] Loaded messageboards in #{query_times[:messageboards]}s"

        # Time the posts query
        query_start = Time.current
        base_query = if messageboards == Thredded::Messageboard.all
                       Thredded::Post.all
                     else
                       Thredded::Post.where(messageboard_id: messageboards)
                     end

        posts_relation = base_query
          .where(moderation_state: 'pending_moderation')
          .includes(:user, :messageboard, :postable)
          .order(created_at: :asc, id: :asc)
          .page(params[:page] || 1)

        # Skip the problematic preload_first_topic_post
        # .preload_first_topic_post

        query_times[:posts_query] = Time.current - query_start
        Rails.logger.info "[MODERATION TIMING] Built posts query in #{query_times[:posts_query]}s"

        # Time the actual loading
        query_start = Time.current
        @posts = Thredded::PostsPageView.new(thredded_current_user, posts_relation)
        posts_count = @posts.to_a.length  # Force loading
        query_times[:posts_load] = Time.current - query_start
        Rails.logger.info "[MODERATION TIMING] Loaded #{posts_count} posts in #{query_times[:posts_load]}s"

        # Handle flash
        maybe_set_last_moderated_record_flash

        # Log total time
        total_time = Time.current - start_time
        Rails.logger.info "[MODERATION TIMING] Total pending action time: #{total_time}s"
        Rails.logger.info "[MODERATION TIMING] Query breakdown: #{query_times.inspect}"

        # Add a warning if it's taking too long
        if total_time > 1.0
          Rails.logger.warn "[MODERATION PERFORMANCE] Moderation page took #{total_time}s to load!"
        end
      end

      private

      # Override to use Kaminari's page method directly
      def current_page
        (params[:page] || 1).to_i
      end
    end
  end
end