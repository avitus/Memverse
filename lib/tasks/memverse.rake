include Parser

namespace :utils do

  #--------------------------------------------------------------------------------------------
  # Group user's memory verses into passages. This should be a one time operation.
  #--------------------------------------------------------------------------------------------
  desc "Group memory verses for each user into passages"
  task :create_passages => :environment do

    puts "=== Creating passages for all users ==="

    User.find_each { |u|

      # Find all starting (or solo verses) and create a passage
      Memverse.where(:user_id => u.id, :first_verse => nil).find_each { |mv|
        pp = Passage.create(
          :user_id        => u.id,
          :length         => 1,
          :reference      => mv.ref,
          :efactor        => mv.efactor,
          :test_interval  => mv.test_interval,
          :rep_n          => 1,
          :next_test      => mv.next_test,
          :last_tested    => mv.last_tested,
          :first_verse    => mv.id)

        if pp
          mv.passage_id = pp.id
          mv.save
        else
          puts("Error creating passage for memory verse (#{mv.ref}) for user (#{u.login})")
        end
      }

      # Find all other verses and add to existing passage
      Memverse.where(:user_id => u.id, Memverse.arel_table[:first_verse].not_eq(nil) ).find_each { |mv|

        mv.add_to_passage

      }
    }

    puts "=== Finished ==="

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
  # Locate out of bound verses -- no longer seems to occur. Run occasionally
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


end




