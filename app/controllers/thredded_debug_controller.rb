class ThreddedDebugController < ApplicationController
  # Skip authentication for testing
  skip_before_action :authenticate_user!, if: -> { action_name == 'test' }

  def test
    render plain: "Thredded debug test successful. Server is running latest code."
  end

  def moderation_test
    # Requires authentication
    unless current_user&.admin?
      render plain: "Not authorized", status: :forbidden
      return
    end

    begin
      # Try to access Thredded moderation data
      @posts = if defined?(Thredded::Post)
        Thredded::Post.where(moderation_state: :pending_moderation).limit(5)
      else
        []
      end

      render json: {
        success: true,
        thredded_defined: defined?(Thredded),
        moderation_controller: defined?(Thredded::ModerationController),
        posts_count: @posts.count,
        current_user: current_user.email,
        rails_env: Rails.env
      }
    rescue => e
      render json: {
        error: e.message,
        backtrace: e.backtrace.first(5)
      }, status: :internal_server_error
    end
  end
end