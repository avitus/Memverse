class UpdateVerseDifficulty


  # Note: This is all commented out as not sure whether it was ever tested and shown to be working (Dec 2017)

  # include Sidekiq::Worker
  # include Sidetiq::Schedulable
  # include IceCube

  # sidekiq_options :retry => false

  # recurrence do
  #   monthly(6).day_of_month(11).hour_of_day(3)    # Run twice per year
  # end

  # def perform

  #   puts "=== Updating verse difficulty at      #{Time.now} ==="

  #   # Calculate average eFactor for each verse
  #   Verse.find_each do |vs|

  #     if vs.memverses.active.count > 10
  #       vs.update_attribute( :difficulty, vs.memverses.active.average(:efactor) )
  #     end

  #   end

  #   # Create a hash of max and min eFactors by translation
  #   efactor_ranges = Hash.new

  #   puts "Difficulty Ranges for Each Translation"
  #   puts "--------------------------------------"

  #   TRANSLATIONS.keys.each do |tl|
  #     efactor_ranges[tl] =
  #       {
  #         :max => Verse.where(:translation => tl.to_s).maximum(:difficulty),
  #         :min => Verse.where(:translation => tl.to_s).minimum(:difficulty)
  #       }

  #     if efactor_ranges[tl][:max] && efactor_ranges[tl][:max]
  #       printf("%s : %g - %g \n", tl.to_s, efactor_ranges[tl][:max], efactor_ranges[tl][:min])
  #     end

  #   end

  #   # Normalize by translation such that 0 = easiest, 100 = hardest
  #   Verse.find_each do |vs|

  #     if vs.difficulty  # will be nil if not enough users are working on the verse

  #       tl_min_difficulty = efactor_ranges[vs.translation.to_sym][:min]
  #       tl_max_difficulty = efactor_ranges[vs.translation.to_sym][:max]

  #       normalized_difficulty = 100 - (( vs.difficulty - tl_min_difficulty ) / ( tl_max_difficulty - tl_min_difficulty ) * 100)
  #       vs.update_attribute( :difficulty, normalized_difficulty )
  #     end
  #   end

  #   puts "=== Completed verse difficulty update #{Time.now} ==="

  # end

end