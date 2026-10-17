module Users
  # Devise sign-up, adjusted so a confirmation email Postmark refused to send is
  # reported to the user rather than promised.
  class RegistrationsController < Devise::RegistrationsController
    # Devise's flash promises a confirmation email. When Postmark refused to send it
    # (see User#send_devise_notification), warn the user instead of leaving them waiting.
    def create
      super
      track_signed_up(resource) if resource.persisted?
      return unless resource.undelivered_devise_notification

      flash.delete(:notice)
      set_flash_message! :alert, :signed_up_but_email_undeliverable
    end

    private

    # Confirmable leaves the new user signed out, and the browser may still carry a
    # visit attributed to whoever was signed in before. Start a fresh visit owned by
    # the new account instead of reusing that one.
    def track_signed_up(user)
      ahoy.reset_visit
      Ahoy::Tracker.new(controller: self, visit_token: SecureRandom.uuid, user: user)
                   .track("signed_up", user_id: user.id, login: user.login)
    rescue StandardError => e
      # Analytics must never break sign-up or the undelivered-email warning that follows.
      Rails.logger.warn("[analytics] signed_up not recorded: #{e.class}: #{e.message}")
    end
  end
end
