# frozen_string_literal: true

# Worker to clean up stale SSE connections periodically
class CleanupSseConnectionsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low, retry: false

  def perform
    Rails.logger.info "Starting SSE connection cleanup"

    connection_manager = SseConnectionManager.instance

    # Clean up stale connections
    connection_manager.cleanup_stale_connections

    # Log statistics
    stats = connection_manager.stats
    Rails.logger.info "SSE connection stats after cleanup: #{stats.inspect}"

    # Alert if too many connections
    if stats[:total_connections] > 400
      Rails.logger.warn "High number of SSE connections: #{stats[:total_connections]}"
    end
  rescue => e
    Rails.logger.error "SSE connection cleanup failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end