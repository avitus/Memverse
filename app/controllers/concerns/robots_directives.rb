# frozen_string_literal: true

# Tells crawlers not to index pages that only duplicate or fragment indexed content:
# forum post permalinks (they 302 to the topic page), and paginated, tagged or
# searched blog and forum listings. Applied both as an X-Robots-Tag header (so it
# also covers redirects) and as the <meta name="robots"> value in the layout.
module RobotsDirectives
  extend ActiveSupport::Concern

  NOINDEX = "noindex, nofollow"
  INDEX   = "all"

  PERMALINK_CONTROLLERS = %w[thredded/post_permalinks thredded/private_post_permalinks].freeze
  ENGINE_PREFIXES       = %w[thredded/ bloggity/].freeze

  included do
    after_action :set_robots_header
    helper_method :robots_directive
  end

  def robots_directive
    noindex_page? ? NOINDEX : INDEX
  end

  private

  def set_robots_header
    response.headers["X-Robots-Tag"] = NOINDEX if noindex_page?
  end

  def noindex_page?
    return true if PERMALINK_CONTROLLERS.include?(controller_path)
    return false unless ENGINE_PREFIXES.any? { |prefix| controller_path.start_with?(prefix) }

    # Legacy blog routes (/blog/blogs/:id/blog_posts) and any listing permutation
    # (?page=, ?tag_name=, ?search=, /page-2) are crawl noise, not content.
    legacy_blog_listing? || params[:page].present? || request.query_parameters.any?
  end

  def legacy_blog_listing?
    controller_path == "bloggity/blog_posts" && action_name == "index" && params[:blog_id].present?
  end
end
