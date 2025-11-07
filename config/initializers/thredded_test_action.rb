# frozen_string_literal: true

# Test action to verify CSRF is the issue

Rails.application.config.after_initialize do
  if defined?(Thredded::ModerationController)
    Thredded::ModerationController.class_eval do
      # Add a test action that skips CSRF
      skip_before_action :verify_authenticity_token, only: [:test_moderate]

      def test_moderate
        Rails.logger.info "[TEST ACTION] test_moderate called successfully"
        Rails.logger.info "[TEST ACTION] Params: #{params.inspect}"

        render json: {
          status: 'ok',
          message: 'Test action reached successfully',
          params_received: params.to_unsafe_h
        }
      end
    end

    # Add route for test action
    Thredded::Engine.routes.draw do
      post '/admin/moderation/test', to: 'moderation#test_moderate', as: :test_moderate

      # Re-add all existing routes
      # (This is needed because routes.draw clears existing routes)
      scope path: 'admin', as: 'admin' do
        resource :moderation, only: [] do
          collection do
            get '/', action: :pending, as: :pending
            get '/history(/page-:page)', action: :history, as: :history, constraints: { page: /[1-9]\d*/ }
            get '/users(/page-:page)', action: :users, as: :users, constraints: { page: /[1-9]\d*/ }
            get '/users/:id(/page-:page)', action: :user, as: :user, constraints: { page: /[1-9]\d*/ }
            get '/activity(/page-:page)', action: :activity, as: :activity, constraints: { page: /[1-9]\d*/ }
            post '/', action: :moderate_post, as: :moderate_post
            post '/user/:id', action: :moderate_user, as: :moderate_user
          end
        end
      end
    end

    Rails.logger.info "[TEST ACTION] Test route added: POST /forum/admin/moderation/test"
  end
end