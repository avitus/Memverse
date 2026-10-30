class RefreshTagCloud

  include Sidekiq::Worker
  include IceCube

  sidekiq_options queue: :low, retry: false

  # Rebuilds every verse's tags from its users' tags. The delete and the rebuild run in one
  # transaction (a savepoint when already inside one) so an error part-way leaves the previous
  # tag cloud in place; the job runs twice a year and is not retried, so a half-built cloud would
  # otherwise stay up for months. A verse that fails validation (Verse#update_tags returns save's
  # false) is skipped with a warning rather than aborting the run: such a verse could never be
  # saved, so raising would block every future rebuild on one bad legacy row.
  def perform
    Sidekiq.logger.info "=== Refreshing tag cloud at #{Time.current} ==="
    skipped = []

    ActiveRecord::Base.transaction(requires_new: true) do
      ActsAsTaggableOn::Tagging.where(:taggable_type => 'Verse').delete_all
      Verse.find_each do |vs|
        skipped << vs.id unless vs.update_tags
      end
    end

    if skipped.any?
      Sidekiq.logger.warn "=== Tag cloud refresh skipped #{skipped.size} verse(s) that did not save: #{skipped.first(20).join(', ')}"
    end
    Sidekiq.logger.info "=== Completed refresh at    #{Time.current} ==="
  end

end
