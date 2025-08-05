# Base controller for API - Converted from RocketPants to Rails API mode
class Api::V1::ApiController < ActionController::API

  # OAuth integration with Doorkeeper
  include Doorkeeper::Rails::Helpers

  # API response helpers
  include ApiResponseHelpers

  # Airbrake support
  # use_named_exception_notifier :airbrake

  #------------- Private below this line -------------------------------------------------------------------------------------
  private

  # Returns the current resource owner, based on the token
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  # Sanitize sort parameters to prevent SQL injection
  # @param sort_param [String] The sort parameter from params
  # @param allowed_columns [Array<String>] List of allowed column names
  # @param allowed_directions [Array<String>] List of allowed sort directions (default: ['ASC', 'DESC'])
  # @return [String, nil] Sanitized sort string or nil if invalid
  def sanitize_sort_param(sort_param, allowed_columns, allowed_directions = ['ASC', 'DESC'])
    return nil if sort_param.blank?
    
    # Handle simple column names
    if allowed_columns.include?(sort_param)
      return connection.quote_column_name(sort_param)
    end
    
    # Handle "column direction" format
    parts = sort_param.split(/\s+/)
    if parts.length == 2
      column, direction = parts
      if allowed_columns.include?(column) && allowed_directions.include?(direction.upcase)
        return "#{connection.quote_column_name(column)} #{direction.upcase}"
      end
    end
    
    # Handle "table.column" format
    if sort_param.include?('.')
      table_column = sort_param.split('.')
      if table_column.length == 2
        table, column = table_column
        if allowed_columns.include?(sort_param) || allowed_columns.include?(column)
          return "#{connection.quote_table_name(table)}.#{connection.quote_column_name(column)}"
        end
      end
    end
    
    nil
  end
  
  def connection
    ActiveRecord::Base.connection
  end

end
