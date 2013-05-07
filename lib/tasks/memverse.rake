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
  # Delete unused tags, recreate verse tags
  # Task duration: ~ 4 hours
  #--------------------------------------------------------------------------------------------
  desc "Input missing NIV 1984 verses"
  task :input_niv => :environment do

    puts "Opening XML file"
    niv = Nokogiri::XML(open('niv-1984.xml'))

    puts "Starting verse upload"
    BIBLEBOOKS.each { |book|

      bi = BIBLEBOOKS.index(book) + 1

      final_chapter = FinalVerse.where(:book => book).order("chapter DESC").first.chapter

      (1..final_chapter).each { |chapter|

        puts "#{bi} #{book} #{chapter}"

        final_verse = FinalVerse.where(:book => book, :chapter => chapter).first.last_verse

        (1..final_verse).each { |verse|

          if !Verse.exists?(:translation => "NIV", :book => book, :chapter => chapter, :versenum => verse)

            text = niv.css("book[name='#{book}'] chapter[name='#{chapter}'] verse[name='#{verse}']").text

            text.gsub!(/—/, ' — ')    # add spaces around em dash
            text.gsub!(/--/, ' — ')   # replace double dash with em dash
            text.gsub!(/\n/, ' ')      # remove newlines
            text.gsub!(/\s{2,}/, ' ')  # remove double space
            text.strip!

            puts "[#{verse}] " + text

            if !text.blank?
              Verse.create!(:translation => 'NIV', :book => book, :chapter => chapter, :versenum => verse, :text => text,
                            :book_index => bi, :verified => true, :checked_by => 'XML Upload')
            end

          end

        }

      }

    }

    puts "=== Completed NIV 1984 input at #{Time.now} ==="

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
    Passage.joins("left join memverses on memverses.passage_id = passages.id").where("memverses.passage_id is null").destroy_all

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




