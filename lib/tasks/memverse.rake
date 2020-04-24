# coding: utf-8

namespace :utils do

  # include Parser

  #--------------------------------------------------------------------------------------------
  # Run backup
  #--------------------------------------------------------------------------------------------
  desc "Backup entire site"
  task :backup => :environment do

    sh "bundle exec backup perform -t site_backup -c config/backup/site_backup.rb"

  end

  #--------------------------------------------------------------------------------------------
  # Delete unused tags, recreate verse tags
  # Task duration: ~ 4 hours
  # Note: Run twice a year as a scheduled Sidekiq job
  #--------------------------------------------------------------------------------------------
  desc "Clean up tag cloud"
  task :refresh_tag_cloud => :environment do

    puts "=== Refreshing tag cloud at #{Time.now} ==="

    # Delete all tags on verse model
    ActsAsTaggableOn::Tagging.where(:taggable_type => 'Verse').delete_all

    # Recreate tags verse by verse
    Verse.find_each { |vs| vs.update_tags }

    puts "=== Completed refresh at    #{Time.now} ==="

  end

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
          :max => Verse.where(translation: tl.to_s).maximum(:difficulty),
          :min => Verse.where(translation: tl.to_s).minimum(:difficulty)
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
          :max => Verse.where(translation: tl.to_s).maximum(:memverses_count),
          :min => Verse.where(translation: tl.to_s).minimum(:memverses_count)
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
  # Clear out old user sessions
  #
  # Best to defragment table after this task
  #
  # > mysql -h mysqlserver -u username -p
  # > use database_name;
  # > optimize table sessions;
  #
  # Task duration: 10-20 minutes
  #--------------------------------------------------------------------------------------------
  desc "Clear expired sessions"
  task :clear_expired_sessions => :environment do
    sql = 'DELETE FROM sessions WHERE updated_at < DATE_SUB(NOW(), INTERVAL 1 MONTH);'
    ActiveRecord::Base.connection.execute(sql)
  end

  #--------------------------------------------------------------------------------------------
  # Input missing NIV 1984 verses
  #--------------------------------------------------------------------------------------------
  desc "Input missing NIV 1984 verses"
  task :input_niv => :environment do

    puts "Opening XML file"
    niv = Nokogiri::XML(open('niv-1984.xml'))
    puts "Starting verse upload"

    BIBLEBOOKS[:en].values.each { |book|

      bi = BIBLEBOOKS[:en].values.index(book) + 1
      final_chapter = FinalVerse.where(book: book).order("chapter DESC").first.chapter

      (1..final_chapter).each { |chapter|

        puts "#{bi} #{book} #{chapter}"
        final_verse = FinalVerse.where(book: book, chapter: chapter).first.last_verse

        (1..final_verse).each { |verse|
          if !Verse.exists?(translation: "NIV", book: book, chapter: chapter, versenum: verse)
            text = niv.css("book[name='#{book}'] chapter[name='#{chapter}'] verse[name='#{verse}']").text
            text.gsub!(/—/, ' — ')     # add spaces around em dash
            text.gsub!(/--/, ' — ')    # replace double dash with em dash
            text.gsub!(/\n/, ' ')      # remove newlines
            text.gsub!(/\s{2,}/, ' ')  # remove double space
            text.strip!
            puts "[#{verse}] " + text
            if !text.blank?
              Verse.create!(translation: 'NIV', book: book, chapter: chapter, versenum: verse, text: text,
                            book_index: bi, :verified => true, :checked_by => 'XML Upload')
            end
          end
        }
      }
    }
    puts "=== Completed NIV 1984 input at #{Time.now} ==="
  end

  #--------------------------------------------------------------------------------------------
  # Create complete table of Bible reference verses
  # Task duration: ~ 4 hours
  #--------------------------------------------------------------------------------------------
  desc "Create complete list of Bible reference verses"
  task :create_uberverses => :environment do

    puts "Starting reference verse creation"
    BIBLEBOOKS[:en].values.each { |book|

      bi = BIBLEBOOKS[:en].values.index(book) + 1

      final_chapter = FinalVerse.where(book: book).order("chapter DESC").first.chapter

      (1..final_chapter).each { |chapter|

        puts "#{bi} #{book} #{chapter}"

        final_verse = FinalVerse.where(book: book, chapter: chapter).first.last_verse

        (1..final_verse).each { |verse|

          if !Uberverse.exists?(book: book, chapter: chapter, versenum: verse, book_index: bi)

            Uberverse.create!(book: book, chapter: chapter, versenum: verse, book_index: bi)

          end

        }

      }

    }

    puts "=== Created Uberverse table at #{Time.now} ==="

  end

  #--------------------------------------------------------------------------------------------
  # Calculate subsection ending probabilities
  # Task duration: ~ 2 hours
  #--------------------------------------------------------------------------------------------
  desc "Calculate probability that any verse ends a subsection"
  task :calc_subsection_probabilities => :environment do

    puts "Starting calculation of subsection probabilities"
    BIBLEBOOKS[:en].values.each { |book|

      bi = BIBLEBOOKS[:en].values.index(book) + 1

      final_chapter = FinalVerse.where(book: book).order("chapter DESC").first.chapter

      (1..final_chapter).each { |chapter|

        subsection_end = Array.new

        final_verse   = FinalVerse.where(book: book, chapter: chapter).first.last_verse
        passage_count = Passage.where("length > 2 AND book = ? AND chapter = ?", book, chapter).count

        if passage_count > 0

          # Create array with number of times this verse is the last verse in a passage
          # We start at 2 because the first verse is obviously a subsection start
          first_verse_count = (2..final_verse).map { |vs|
            Passage.where("length > 2 AND book = ? AND chapter = ? AND first_verse = ?", book, chapter, vs).count
          }

          # Create array with number of times this verse is the last verse in a passage
          # We skip the last verse because it is obviously a subsection end for our purposes
          last_verse_count = (1..final_verse-1).map { |vs|
            Passage.where("length > 2 AND book = ? AND chapter = ? AND last_verse = ?", book, chapter, vs).count
          }

          # Add the two arrays to give an idea of the probability that this is usually an end verse
          # Idea: if subsequent verse is a first verse or this is an end verse then this is a good dividing point
          end_prob = first_verse_count.zip(last_verse_count).map {|x| (x.sum / passage_count.to_f * 100).to_i }

          # Pad probability array
          padded_end_prob = [0,0,0] + end_prob + [0,0,0]

          # Extract peaks as most likely passage breaks
          for i in 0..end_prob.length-1
            subsection_end[i] = -padded_end_prob[i  ]/6 \
                                -padded_end_prob[i+1]/4 \
                                -padded_end_prob[i+2]/2 \
                                +padded_end_prob[i+3]   \
                                -padded_end_prob[i+4]/2 \
                                -padded_end_prob[i+5]/4 \
                                -padded_end_prob[i+6]/6
          end

          # Remove negative values
          subsection_end.map! { |p| [p,0].max }
          subsection_end.push(100)    # Add final verse

          # Show output
          puts "#{book} #{chapter} : #{subsection_end}"

          # Save to DB
          subsection_end.each_with_index { |p, vs|
            Uberverse.where(book: book, chapter: chapter, versenum: vs+1).first.update_attribute(:subsection_end, p)
          }

        end

      }

    }

    puts "=== Finished calculating subsection probabilities at #{Time.now} ==="

  end

  #--------------------------------------------------------------------------------------------
  # Calculate subsections for passages of active users
  # Task duration: ~ ? hours
  #--------------------------------------------------------------------------------------------
  desc "Create subsections for active users' passages"
  task :subsection_passages => :environment do
    puts "=== Creating subsections for active users' passages at #{Time.now} ==="

    User.active.find_each { |u|
      u.passages.find_each { |psg|
        psg.auto_subsection
      }
    }

    puts "=== Finished updating passage subsections at #{Time.now} ==="
  end

  #--------------------------------------------------------------------------------------------
  # Insert missing book_index values for Passages
  # Task duration: ~ 5 mins
  #--------------------------------------------------------------------------------------------
  desc "Insert missing book_index values for passage model"
  task :insert_missing_book_index => :environment do
    puts "=== Inserting missing book_index values for passage model at #{Time.now} ==="

    Passage.where(book_index: nil).find_each { |psg|
      psg.update_attribute(:book_index, Book.find_by_name(psg.book).try(:book_index))
    }

    puts "=== Finished inserting missing book_index values at #{Time.now} ==="
  end

  #--------------------------------------------------------------------------------------------
  # Associate verses with uberverses
  # Task duration: ~ 4 hours
  #--------------------------------------------------------------------------------------------
  desc "Associate Verses with Uberverses"
  task :associate_verses_with_uberverses => :environment do

    puts "=== Starting associating Verses with Uberverses at #{Time.now} ==="

    Verse.find_each { |vs|

      uv = Uberverse.where(book: vs.book, chapter: vs.chapter, versenum: vs.versenum).first

      if uv
        vs.update_attribute(:uberverse_id, uv.id)
      else
        puts " -- no Uberverse for: #{vs.ref} (#{vs.translation})"
      end

    }

    puts "=== Finished associating Verses with Uberverses at #{Time.now} ==="

  end


  #--------------------------------------------------------------------------------------------
  # Group user's memory verses into passages. This should be a one time operation.
  #--------------------------------------------------------------------------------------------
  desc "Group memory verses for each user into passages"
  task :create_passages => :environment do

    puts "=== Creating passages for all users ==="

    User.find_each { |u|

      puts "---- #{u.id}: #{u.name_or_login}"

      # Find all starting (or solo verses) and create a passage
      Memverse.where(:user_id => u.id, :first_verse => nil).find_each { |mv|
        pp = Passage.create!(

          :user_id        => u.id,

          :reference      => mv.verse.ref,
          :translation    => mv.verse.translation,

          :book           => mv.verse.book,
          :chapter        => mv.verse.chapter,
          :first_verse    => mv.verse.versenum,
          :last_verse     => mv.verse.versenum,

          :length         => 1,

          :efactor        => mv.efactor,
          :test_interval  => mv.test_interval,
          :rep_n          => 1,
          :next_test      => mv.next_test,
          :last_tested    => mv.last_tested )

        if pp
          puts("------------ Adding #{mv.verse.ref}")
          mv.passage_id = pp.id
          mv.save
        else
          puts("Error creating passage for memory verse (#{mv.ref}) for user (#{u.login})")
        end
      }

      # Find all other verses and add to existing passage
      Memverse.where(:user_id => u.id).where(Memverse.arel_table[:first_verse].not_eq(nil)).find_each { |mv|
        puts("------------ Adding #{mv.verse.ref}")
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

        Passage.where(:user_id => u.id, translation: psg.translation, book: psg.book, chapter: psg.chapter).find_each { |near_psg|

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
      if Verse.where(translation: vs.translation, book_index: vs.book_index, chapter: vs.chapter, versenum: vs.versenum).count > 1
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




