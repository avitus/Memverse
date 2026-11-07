module HeritageHelper
  def heritage_enabled?
    ENV.fetch('MEMVERSE_HERITAGE', Rails.env.staging? ? '1' : '0') == '1'
  end

  def heritage_auth_page?
    devise_controller? && %w[sessions registrations passwords confirmations].include?(controller_name) && !user_signed_in?
  end

  def heritage_auth_content
    if controller_name == 'passwords'
      action_name == 'new' || action_name == 'create' ? ['Account recovery', 'Forgot your password?', 'A way back in.', 'We’ll help you get back to your verses, one step at a time.'] : ['Account recovery', 'Choose a new password.', 'Ready for a fresh start.', 'Your verses and progress stay with your account.']
    elsif controller_name == 'confirmations'
      ['Email confirmation', 'Confirm your email.', 'Almost ready to begin.', 'Confirm your email address, sign in, and choose your first verse.']
    elsif controller_name == 'registrations'
      ['Begin your practice', 'Create your account.', 'Start with one verse.', 'Choose words that matter to you. Learn them at your own pace, then keep them close through regular review.']
    else
      ['Welcome back', 'Sign in.', 'A little time. A lasting treasure.', 'Pick up where you left off. Your verses and progress will be waiting.']
    end
  end
end
