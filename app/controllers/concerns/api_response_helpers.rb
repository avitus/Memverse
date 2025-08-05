# API Response Helpers - Replacement for RocketPants functionality
# Provides expose() and error!() methods to maintain compatibility
module ApiResponseHelpers
  extend ActiveSupport::Concern

  included do
    # Enable controller-level caching
    class_attribute :cached_actions, default: {}
  end

  class_methods do
    # Replacement for RocketPants caches() method
    # Usage: caches :index, :show, caches_for: 15.minutes
    def caches(*actions, caches_for: 5.minutes)
      actions.each do |action|
        self.cached_actions = cached_actions.merge(action.to_s => caches_for)
      end
    end
  end

  private

  # Replacement for RocketPants expose() method
  # Renders JSON response with RocketPants-compatible structure
  def expose(data, options = {})
    cache_key = cache_key_for_action
    cache_duration = self.class.cached_actions[action_name.to_s]
    
    response_data = if cache_duration && cache_key
      Rails.cache.fetch(cache_key, expires_in: cache_duration) do
        build_response_data(data, options)
      end
    else
      build_response_data(data, options)
    end

    render json: response_data, status: options[:status] || :ok
  end

  # Build response data structure compatible with RocketPants format
  def build_response_data(data, options = {})
    case data
    when ActiveRecord::Relation, Array
      # Handle collections with pagination - RocketPants format
      if data.respond_to?(:current_page) # Kaminari pagination
        {
          response: data.as_json(options),
          count: data.total_count,
          page: data.current_page,
          page_count: data.total_pages,
          per_page: data.limit_value,
          pagination: {
            pages: data.total_pages,
            count: data.total_count
          }
        }
      else
        {
          response: data.as_json(options),
          count: data.size
        }
      end
    else
      # Handle single objects - RocketPants format
      {
        response: data.as_json(options)
      }
    end
  end

  # Generate cache key for current action
  def cache_key_for_action
    parts = [controller_name, action_name]
    parts << params[:id] if params[:id].present?
    parts << params[:page] if params[:page].present?
    parts.join('/')
  end

  # Replacement for RocketPants error!() method
  # Renders RocketPants-compatible error responses
  def error!(status, options = {})
    error_response = {
      error: status.to_s
    }
    
    # Add metadata fields at root level (RocketPants format)
    if options[:metadata]
      options[:metadata].each do |key, value|
        error_response[key.to_s] = value
      end
    end

    render json: error_response, status: status
  end

  # Maps status symbols to HTTP status codes and messages
  def error_message_for(status)
    case status
    when :bad_request
      "Bad Request"
    when :unauthorized  
      "Unauthorized"
    when :forbidden
      "Forbidden"
    when :not_found
      "Not Found"
    when :unprocessable_entity
      "Unprocessable Entity"
    when :internal_server_error
      "Internal Server Error"
    else
      status.to_s.humanize
    end
  end
end