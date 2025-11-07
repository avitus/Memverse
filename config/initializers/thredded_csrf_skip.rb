# frozen_string_literal: true

# Skip CSRF verification for Thredded moderation actions by authenticated admins
# This is a targeted fix for the production 500 error

Rails.application.config.after_initialize do
  if defined?(Thredded::ModerationController)
    Rails.logger.info "[CSRF SKIP] Patching Thredded::ModerationController to skip CSRF for admins"

    Thredded::ModerationController.class_eval do
      # Skip CSRF verification for admin users on moderation actions
      skip_before_action :verify_authenticity_token, only: [:moderate_post, :moderate_user], if: :admin_user?

      private

      def admin_user?
        # Check if current user is an admin
        is_admin = current_user && current_user.admin?
        Rails.logger.info "[CSRF SKIP] User #{current_user&.id} admin check: #{is_admin}"
        is_admin
      end
    end

    Rails.logger.info "[CSRF SKIP] CSRF skip for admin moderation actions applied"
  else
    Rails.logger.warn "[CSRF SKIP] Thredded::ModerationController not found"
  end
end

Rails.logger.info "[CSRF SKIP] Initializer loaded at #{Time.now}"