# coding: utf-8

namespace :utils do

  # include Parser

  #--------------------------------------------------------------------------------------------
  # Update difficulty for each verse
  # Task duration: ~ 6 mins
  #--------------------------------------------------------------------------------------------
  desc "Update verse difficulty"
  task :update_verse_difficulty => :environment do

    puts "=== Updating verse difficulty at      #{Time.now} ==="

    # Calculate average eFactor for each verse
    Verse.find_each do |vs|

      if vs.memverses.active.count > 10
        vs.update_attribute( :difficulty, vs.memverses.active.average(:efactor) )
      end

    end

    # Create a hash of max and min eFactors by translation
    efactor_ranges = Hash.new

    puts "Difficulty Ranges for Each Translation"
    puts "--------------------------------------"

    TRANSLATIONS.keys.each do |tl|
      efactor_ranges[tl] =
        {
          :max => Verse.where(:translation => tl.to_s).maximum(:difficulty),
          :min => Verse.where(:translation => tl.to_s).minimum(:difficulty)
        }

      if efactor_ranges[tl][:max] && efactor_ranges[tl][:max]
        printf("%s : %g - %g \n", tl.to_s, efactor_ranges[tl][:max], efactor_ranges[tl][:min])
      end

    end

    # Normalize by translation such that 0 = easiest, 100 = hardest
    Verse.find_each do |vs|

      if vs.difficulty  # will be nil if not enough users are working on the verse

        tl_min_difficulty = efactor_ranges[vs.translation.to_sym][:min]
        tl_max_difficulty = efactor_ranges[vs.translation.to_sym][:max]

        normalized_difficulty = 100 - (( vs.difficulty - tl_min_difficulty ) / ( tl_max_difficulty - tl_min_difficulty ) * 100)
        vs.update_attribute( :difficulty, normalized_difficulty )
      end
    end

    puts "=== Completed verse difficulty update #{Time.now} ==="

  end

  #--------------------------------------------------------------------------------------------
  # Update popularity for each verse
  # Task duration: ~ 10 mins
  #--------------------------------------------------------------------------------------------
  desc "Update verse popularity"
  task :update_verse_popularity => :environment do

    puts "=== Updating verse popularity at      #{Time.now} ==="

    # Create a hash of max and min eFactors by translation
    count_ranges = Hash.new

    puts "Popularity Ranges for Each Translation"
    puts "--------------------------------------"

    TRANSLATIONS.keys.each do |tl|
      count_ranges[tl] =
        {
          :max => Verse.where(:translation => tl.to_s).maximum(:memverses_count),
          :min => Verse.where(:translation => tl.to_s).minimum(:memverses_count)
        }

      if count_ranges[tl][:max] && count_ranges[tl][:max]
        printf("%s : %g - %g \n", tl.to_s, count_ranges[tl][:max], count_ranges[tl][:min])
      end

    end

    # Normalize by translation such that 0 = least popular, 100 = most popular
    Verse.find_each do |vs|

      # If verses exist with invalid translation then run the following
      # Verse.where("translation NOT IN (?)", TRANSLATIONS.keys) and destroy_all
      tl_max_usage = Math::log10( [count_ranges[vs.translation.to_sym][:max], 1].max )  # ensure we're not taking log of 0

      if tl_max_usage > 0
        normalized_usage = ( Math::log10( [vs.memverses_count, 1].max )  ) / tl_max_usage * 100
        vs.update_attribute( :popularity, normalized_usage )
      else
        vs.update_attribute( :popularity, 50) # No real data ... should only occur with translations that aren't really used
      end

    end

    puts "=== Completed verse popularity update #{Time.now} ==="

  end

  #--------------------------------------------------------------------------------------------
  # Locate broken links between memory verses
  #--------------------------------------------------------------------------------------------
  desc "Locate broken links between memory verses"
  task :locate_broken_links => :environment do

    puts("Locating broken links for #{User.active.count} users.")

    User.active.find_each { |u|

      Memverse.where(:user_id => u.id).find_each { |mv|

        # NOTE: we use mv.update_column rather than mv.save to prevent the after_save callbacks from being triggered and updating the users
        #       last activity date.

        if mv.prev_verse != mv.get_prev_verse
          puts("[#{u.id} - #{u.email}] Need to add linkage to previous verse for memory verse #{mv.id} (#{mv.verse.ref}) created at #{mv.created_at}")
          mv.update_column(:prev_verse, mv.get_prev_verse)
        end

        if mv.next_verse != mv.get_next_verse
          puts("[#{u.id} - #{u.email}] Need to add linkage to the next verse for memory verse #{mv.id} (#{mv.verse.ref}) created at #{mv.created_at}")
          mv.update_column(:next_verse, mv.get_next_verse)
        end

        # TODO: Need to fix first verse entry as well
        if mv.first_verse != mv.get_first_verse
          puts("[#{u.id} - #{u.email}] Need to add linkage to the  1st verse for memory verse #{mv.id} (#{mv.verse.ref}) created at #{mv.created_at}")
          mv.update_column(:first_verse, mv.get_first_verse)
        end

      }
    }

    puts "=== Finished ==="

  end

  #--------------------------------------------------------------------------------------------
  # Locate broken passages
  # Task duration: 4 minutes
  # Last detected problem: 4-30-2016
  # Last ran task:         4-30-2016
  #--------------------------------------------------------------------------------------------
  desc "Locate broken passages"
  task :locate_broken_passages => :environment do

    puts("Locating broken passages for #{User.active.count} users.")

    User.active.find_each { |u|

      Passage.where(:user_id => u.id).find_each { |psg|

        Passage.where(:user_id => u.id, :translation => psg.translation, :book => psg.book, :chapter => psg.chapter).find_each { |near_psg|

          if psg.first_verse == near_psg.last_verse + 1
            puts("[#{u.id} - #{u.email}] Passage #{psg.reference} should be joined to passage #{near_psg.reference}")

            # display offending memory verses
            puts("   Passage 1" )
            psg.memverses.each { |mv|
              puts("   [#{mv.id} - #{mv.verse.ref} ] was created at #{mv.created_at}")
            }

            puts("   Passage 2" )
            near_psg.memverses.each { |mv|
              puts("   [#{mv.id} - #{mv.verse.ref} ] was created at #{mv.created_at}")
            }

            psg.absorb( near_psg ) # Join the two passages
          end

        }

      }
    }

    # Remove all empty passages
    puts("Removing passages with no associated memory verses")
    puts("   #{Passage.joins("left join memverses on memverses.passage_id = passages.id").where("memverses.passage_id is null").count} empty passages")
    Passage.joins("left join memverses on memverses.passage_id = passages.id").readonly(false).where("memverses.passage_id is null").destroy_all

    puts "=== Finished ==="

  end

  #--------------------------------------------------------------------------------------------
  # Locate out of bound verses -- no longer seems to occur. Run occasionally
  # Task duration: 4 minutes
  # Last detected problem: (A long time ago)
  # Last ran task:         4-30-2016
  #--------------------------------------------------------------------------------------------
  desc "Locate out of bound verses"
  task :locate_oob_verses => :environment do

    puts "=== Locating (and deleting) out of bound verses ==="

    Verse.find_each { |vs|
      if !vs.end_of_chapter_verse || vs.versenum > vs.end_of_chapter_verse.last_verse
        puts("#{vs.id} : #{vs.ref} [#{vs.created_at.to_date}] - #{vs.text}")
        # vs.destroy
      end
    }

    puts "=== Finished ==="

  end

  #--------------------------------------------------------------------------------------------
  # Detect duplicate verses. Rarely occurs but should run this task periodically
  #--------------------------------------------------------------------------------------------
  desc "Detect duplicate verses"
  task :find_duplicate_verses => :environment do

    puts "=== Finding duplicate verses ==="

    Verse.find_each { |vs|
      if Verse.where(:translation => vs.translation, :book_index => vs.book_index, :chapter => vs.chapter, :versenum => vs.versenum).count > 1
        puts("[#{vs.id}] #{vs.created_at} -- #{vs.ref} (#{vs.translation}) -- Associated memory verses: #{vs.memverses.count}")
        if vs.memverses.count == 0
          puts("  ^--- Deleting this verse since it has no associated memory verses.")
          vs.destroy
        elsif vs.memverses.count == 1
          puts("  ^--- User: #{vs.memverses.first.user.email} was last active on #{vs.memverses.first.user.last_activity_date}")
        else
          # Do nothing
        end
      end
    }

    puts "=== Finished ==="

  end

  #--------------------------------------------------------------------------------------------
  # Locate memverses that have a passage_id of a nonexistent passage
  # Note: this is an ongoing problem as of Aug 2015
  # Task duration: 30 minutes
  # Last detected problem: 4-30-2016 (1 memverse)
  # Last ran task:         4-30-2016
  #--------------------------------------------------------------------------------------------
  desc "Locate memverses that have a passage_id of a nonexistent passage"
  task :locate_nil_passage_pointers => :environment do

    puts "=== Locating nil passage pointers at #{Time.now} ==="

    broken_passage_count = 0

    Memverse.find_each { |mv|
      if mv.passage.nil?
        
        puts("Memverse with ID #{mv.id} for user #{mv.user.email} has nonexistent passage_id: #{mv.passage_id}")
        
        broken_passage_count = broken_passage_count + 1

        # Fix the problem
        mv.add_to_passage

      end
    }

    puts "=== Located #{broken_passage_count} memverses with a bad passage_id ==="
    puts "=== Finished at #{Time.now} ==="

  end


end




