namespace :utils do
  desc "Locate broken links between memory verses"
  task :locate_broken_links => :environment do
  
    User.find_each { |u|
    
      puts "Locating broken memory verse links for user #{u.email}"
    
      Memverse.where(:user_id => u.id).find_each { |mv|
        
        if mv.prev_verse != mv.get_prev_verse
          puts("  Need to add linkage to previous verse for memory verse #{mv.id}")
          # mv.prev_verse = mv.get_prev_verse unless !repair
        end
        
        if mv.next_verse != mv.get_next_verse
          puts("  Need to add linkage to next verse for memory verse #{mv.id}")
          # mv.next_verse = mv.get_next_verse unless !repair     
        end
  
        # TODO: Need to fix first verse entry as well
        if mv.first_verse != mv.get_first_verse
          puts("  Need to add linkage to first verse for memory verse #{mv.id}")
          # mv.first_verse = mv.get_first_verse unless !repair       
        end
                
      }        
    }
  
  end
end
