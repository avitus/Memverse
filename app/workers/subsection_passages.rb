class SubsectionPassages

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include IceCube

  sidekiq_options :retry => false

  recurrence do
    monthly(6).day_of_month(6).hour_of_day(1)    # Run twice per year the day after verse end probabilities are updated
  end

  def perform

    puts "Creating subsections for active users' passages."

    User.active.find_each { |u|
      u.passages.find_each { |psg|
        psg.auto_subsection
      }
    }

    puts "=== Finished updating passage subsections at #{Time.now} ==="

  end

end