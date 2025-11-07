class DebugController < ApplicationController
  def thredded_status
    status = {
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION,
      environment: Rails.env,
      thredded_defined: defined?(Thredded) ? 'Yes' : 'No',
      moderate_post_defined: defined?(Thredded::ModeratePost) ? 'Yes' : 'No',
      moderation_controller_defined: defined?(Thredded::ModerationController) ? 'Yes' : 'No'
    }

    if defined?(Thredded::Post)
      status[:moderation_states] = Thredded::Post.moderation_states
    end

    # Check if our optimization loaded
    if defined?(Thredded::ModeratePost) && Thredded::ModeratePost.respond_to?(:original_run!)
      status[:optimization_loaded] = 'Yes - original_run! method exists'
    else
      status[:optimization_loaded] = 'No - original_run! method not found'
    end

    render json: status
  end
end