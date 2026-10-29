class RefreshTagCloud

  include Sidekiq::Worker
  include IceCube

  sidekiq_options queue: :low, retry: false

  # Rebuilds every verse's tags from its users' tags. The delete and the rebuild run in one
  # transaction (a savepoint when already inside one) so a failure part-way leaves the previous
  # tag cloud in place; the job runs twice a year and is not retried, so a half-built cloud would
  # otherwise stay up for months.
  def perform
    Sidekiq.logger.info "=== Refreshing tag cloud at #{Time.current} ==="

    ActiveRecord::Base.transaction(requires_new: true) do
      ActsAsTaggableOn::Tagging.where(:taggable_type => 'Verse').delete_all
      Verse.find_each { |vs| vs.update_tags }
    end

    Sidekiq.logger.info "=== Completed refresh at    #{Time.current} ==="
  end

end
