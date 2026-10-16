module Users
  # Devise sign-up, adjusted so a confirmation email Postmark refused to send is
  # reported to the user rather than promised.
  class RegistrationsController < Devise::RegistrationsController
    # Devise's flash promises a confirmation email. When Postmark refused to send it
    # (see User#send_devise_notification), warn the user instead of leaving them waiting.
    def create
      super
      return unless resource.undelivered_devise_notification

      flash.delete(:notice)
      set_flash_message! :alert, :signed_up_but_email_undeliverable
    end
  end
end
