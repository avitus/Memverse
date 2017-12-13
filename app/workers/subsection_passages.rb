class SubsectionPassages

  include Sidekiq::Worker
  include IceCube

  sidekiq_options :retry => false

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