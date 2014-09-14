class RefreshTagCloud

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include IceCube

  sidekiq_options :retry => false

  recurrence do
    monthly(6).day_of_month(6).hour_of_day(1)    # Run twice per year
  end

  def perform

    puts "=== Refreshing tag cloud at #{Time.now} ==="

    # Delete all tags on verse model
    ActsAsTaggableOn::Tagging.where(:taggable_type => 'Verse').delete_all

    # Recreate tags verse by verse
    Verse.find_each { |vs| vs.update_tags }

    puts "=== Completed refresh at    #{Time.now} ==="


  end

end