# frozen_string_literal: true

# Records a server-side Ahoy "$view" event for every successful HTML page load,
# attributes the visit to the signed-in user, and skips admin and API traffic.
# Events for product actions (sign-up, verse added, verse rated, reference test)
# are tracked in the controllers that handle them. See documentation/ANALYTICS.md.
module AnalyticsTracking
  extend ActiveSupport::Concern

  PAGE_VIEW_EVENT = "$view"

  # controller_path prefixes that are never tracked: admin tooling and non-page endpoints
  UNTRACKED_CONTROLLER_PREFIXES = %w[admin/ utils rails_admin/ api/ apidocs ckeditor/ turbo/].freeze

  included do
    after_action :track_page_view
  end

  private

  def track_page_view
    return unless trackable_page_view?

    ahoy.authenticate(current_user) if current_user
    ahoy.track PAGE_VIEW_EVENT, page_view_properties
  rescue StandardError => e
    # Analytics must never break a page.
    Rails.logger.warn("[analytics] page view not recorded: #{e.class}: #{e.message}")
  end

  def trackable_page_view?
    request.get? &&
      !request.xhr? &&
      response.status == 200 &&
      response.media_type == "text/html" &&
      !untracked_controller?
  end

  def untracked_controller?
    UNTRACKED_CONTROLLER_PREFIXES.any? { |prefix| controller_path.start_with?(prefix) }
  end

  def page_view_properties
    {
      controller: controller_path,
      action: action_name,
      path: request.path.to_s.first(255),
      locale: I18n.locale.to_s
    }
  end
end
