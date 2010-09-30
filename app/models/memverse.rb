  #    t.integer  "user_id",                                     :null => false
  #    t.integer  "verse_id",                                    :null => false
  #    t.decimal  "efactor",       :precision => 5, :scale => 1, :default => 0.0
  #    t.integer  "test_interval",                               :default => 1
  #    t.integer  "rep_n",                                       :default => 1
  #    t.date     "next_test"
  #    t.date     "last_tested"
  #    t.string   "status"
  #    t.integer  "attempts",                                    :default => 0
  #    t.datetime "created_at"
  #    t.datetime "updated_at"
  #    t.integer  "first_verse"
  #    t.integer  "prev_verse"
  #    t.integer  "next_verse"
  #    t.integer  "ref_interval"                                 :default => 1
  #    t.date     "next_ref_test'

class Memverse < ActiveRecord::Base

  acts_as_taggable # Alias for 'acts_as_taggable_on :tags'
    
  # Relationships
  belongs_to  :user
  belongs_to  :verse
  
  # Named Scopes
  named_scope :memorized,     :conditions => { :status => "Memorized" }
  named_scope :learning,      :conditions => { :status => "Learning" }
  named_scope :current, lambda { {:conditions => ['next_test >= ?', Date.today ]} }
  named_scope :american,      :include => {:user, :country}, :conditions => { 'countries.printable_name' => 'United States' }
  named_scope :old_testament, :include => :verse, :conditions => { 'verses.book_index' =>  1..39 }
  named_scope :new_testament, :include => :verse, :conditions => { 'verses.book_index' => 40..66 }
  
  named_scope :history,   :include => :verse, :conditions => { 'verses.book_index' =>  1..17 }
  named_scope :wisdom,    :include => :verse, :conditions => { 'verses.book_index' => 18..22 }
  named_scope :prophecy,  :include => :verse, :conditions => { 'verses.book_index' => 23..39 }
  named_scope :gospel,    :include => :verse, :conditions => { 'verses.book_index' => 40..43 }
  named_scope :epistle,   :include => :verse, :conditions => { 'verses.book_index' => 45..65 }
    
  # Validations
  validates_presence_of :user_id, :verse_id

  # ----------------------------------------------------------------------------------------------------------
  # Implement counter caches for number of verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def after_save
    self.update_counter_cache
  end
  
  def after_destroy
    self.update_counter_cache
  end
  
  def update_counter_cache
    self.user.memorized = Memverse.count(:all, :conditions => ["user_id = ? and status = ?", self.user.id, "Memorized"])
    self.user.learning  = Memverse.count(:all, :conditions => ["user_id = ? and status = ?", self.user.id, "Learning"])
    self.user.last_activity_date = Date.today
    self.user.save
  end


  # ----------------------------------------------------------------------------------------------------------
  # Implementation of SM-2 algorithm
  # Inputs:
  #     q             - result of test
  #     n             - current iteration in learning sequence
  #     interval      - interval in days before next test
  #     efactor       - easiness factor
  #
  # Outputs:
  #     n_new         - increment by 1 unless answer was incorrect
  #     efactor_new   - updated efactor
  #     interval_new  - new interval
  # ----------------------------------------------------------------------------------------------------------     
  def supermemo(q)
    
    prev_learning = (self.status == "Learning")
    
    if q<3 # answer was incorrect
      n_new = 1  # Start from the beginning
    else
      n_new = self.rep_n + 1 # Go on to next iteration
    end
    
    # Q  Change in EF
    # ~~~~~~~~~~~~~~~~
    # 0     -0.80
    # 1     -0.54
    # 2     -0.32
    # 3     -0.14
    # 4     +0.00
    # 5     +0.10
 
    efactor_new = [ self.efactor - 0.8 + (0.28 * q) - (0.02 * q * q), 2.5 ].min # Cap eFactor at 2.5
    if efactor_new < 1.2       
      efactor_new = 1.2 # Set minimum efactor to 1.2
    end    
    
    # Calculate new interval
    interval_new = case n_new
      when 1 then 1
      when 2 then 4
      else [self.test_interval * efactor_new, self.user.max_interval.to_i].min.round # Don't set interval to more than one year for now
    end  
    
    # Update memory verse parameters
    self.rep_n          = n_new
    self.efactor        = efactor_new
    self.test_interval  = interval_new
    self.next_test      = Date.today + interval_new
    self.last_tested    = Date.today
    self.status         = interval_new > 30 ? "Memorized" : "Learning"
    self.attempts       += 1      
    self.save
    # TODO: We should check that the verse has been saved before moving on ... otherwise you could reload the same verse if it isn't finished saving    
    
    return (prev_learning and (self.status == "Memorized")) 
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return length of verse sequence
  # Input: memverse_id
  # Returns: length of memory verse sequence
  # ----------------------------------------------------------------------------------------------------------   
  def sequence_length 
    if self.solo_verse? # not part of a sequence
      return 1
    else
      length = 1
      if self.first_verse
        initial_mv = Memverse.find( self.first_verse )
      else
        initial_mv = self
      end
      
      x = initial_mv
      while x.next_verse
        x = Memverse.find(x.next_verse)
        length += 1    
      end   
      return length
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Delete accounts of users that never added any verses
  # ----------------------------------------------------------------------------------------------------------  
  def self.delete_unstarted_memory_verses    
    find(:all, :conditions => [ "created_at < ? and attempts = ?", 6.months.ago, 0 ]).each { |mv|
      # mv.destroy
      logger.info("Removing memory verse #{mv.verse.ref} belong to #{mv.user.login}")
    }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check for users with duplicates
  # ----------------------------------------------------------------------------------------------------------  
  def self.check_for_duplicates
    
    users_with_problems = Array.new
    
    mv_num = 0   
    all_mv = self.count
    
    logger.info("Number of memory verses to check: #{all_mv}")
    
    while mv_num < all_mv
      to_check = find(:first, :conditions => {:id => mv_num})      
      if to_check
        # get the next verse in the database
        the_next_mv = find(:first, :conditions => {:id => mv_num+1})
        if the_next_mv
          # check for same verse_id and user_id
          if (to_check.verse_id == the_next_mv.verse_id) and (to_check.user_id == the_next_mv.user_id)
            logger.warn("*** Alert: #{to_check.user.login} has verse #{to_check.verse.ref} twice in his/her list")
            users_with_problems << to_check.user 
            # TODO: remove duplicate verse, then fix verse linkage
          end
        end
      end
      mv_num += 1
    end
    
    return users_with_problems
  end  


  # ----------------------------------------------------------------------------------------------------------
  # Sort Memory Verse objects according to biblical book order
  # ----------------------------------------------------------------------------------------------------------    
  def <=>(o)
   
   # Compare book
   book_cmp = self.verse.book_index.to_i <=> o.verse.book_index.to_i
   return book_cmp unless book_cmp == 0

   # Compare chapter
   chapter_cmp = self.verse.chapter.to_i <=> o.verse.chapter.to_i
   return chapter_cmp unless chapter_cmp == 0

   # Compare verse
   verse_cmp = self.verse.versenum.to_i <=> o.verse.versenum.to_i
   return verse_cmp unless verse_cmp == 0

   # Otherwise, compare IDs
   return self.id <=> o.id
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Return entire chapter as array
  # ----------------------------------------------------------------------------------------------------------   
  def chapter
    self.part_of_entire_chapter? ? self.passage : nil
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # User has entire chapter: i.e. does user have the last first in the chapter and is it linked to the 1st verse
  # ----------------------------------------------------------------------------------------------------------  
  def part_of_entire_chapter?
    
    eocv = self.verse.end_of_chapter_verse
    
    # Sept 22, 2010 -- eocv occasionally equal to nil ... not sure why
    if eocv and lv = self.user.has_verse?(eocv.book, eocv.chapter, eocv.last_verse)
      # check that it's linked to the first verse
      lv.linked_to_first_verse?                               
    else
      false
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # User has entire chapter memorized
  # Returns: true                       - if entire passage is memorized
  #          false                      - if user isn't learning entire passage
  #          [true, false, false ... ]  - if user hasn't memorized entire passage (not implemented)
  # ----------------------------------------------------------------------------------------------------------  
  def chapter_memorized?
    
    if self.part_of_entire_chapter?
      self.passage.map { |vs| 
        vs.memorized?
      }.all?
    else
      false
    end
  end

    
  # ----------------------------------------------------------------------------------------------------------
  # Returns array of Memverse objects that form passage
  # ----------------------------------------------------------------------------------------------------------      
  def passage
    
    return nil if self.solo_verse?
    
    passage     = Array.new
    
    if self.is_first_verse?
      passage << self
    else
      first_verse = Memverse.find(self.first_verse)
      passage << first_verse
    end
    
    while passage.last.next_verse
      passage << Memverse.find(passage.last.next_verse)
    end
    
    return passage
    
  end


  # ----------------------------------------------------------------------------------------------------------
  # Is a verse memorized?
  # ----------------------------------------------------------------------------------------------------------    
  def memorized?
    self.status == "Memorized"
  end



  # ----------------------------------------------------------------------------------------------------------
  # Is this the first verse in a sequence or a solo verse ?
  # ----------------------------------------------------------------------------------------------------------  
  def is_first_verse?
    return !self.prev_verse
  end

  # ----------------------------------------------------------------------------------------------------------
  # Is this verse linked to the first verse of a chapter?
  # ----------------------------------------------------------------------------------------------------------
  # TODO: what should we return if this is the first verse?  
  def linked_to_first_verse?
    if self.solo_verse?
      return false
    elsif self.first_verse
      Memverse.find(self.first_verse).verse.versenum.to_i == 1
    else
      return false
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return first  verse in a sequence
  # ----------------------------------------------------------------------------------------------------------  
  def first_verse_in_sequence    
    if self.first_verse
      initial_mv = find( self.first_verse )
    else
      initial_mv = self
    end
    
    return initial_mv
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return first overdue verse in a sequence
  # Input: memverse_id (can be a single verse or any verse in a sequence)
  # Returns: first overdue verse (will return the last verse if no verses are due. That's acceptable for now 
  #          since we're only likely to call this function when we know one of the verses needs review.
  # ----------------------------------------------------------------------------------------------------------   
  def first_verse_due_in_sequence 
    
    slack         =  7 # Add some slack to avoid having to review the entire sequence too soon afterwards
    min_test_freq = 60 # Minimum test frequency in days for entire sequence 
    
    if self.solo_verse? # not part of a sequence
      return self
    else
      
      # find the first verse - we don't know whether this is the first verse so need to check
      # TODO: Can replace with first_verse_in_sequence method above (once thoroughly tested)
      if self.first_verse
        initial_mv = Memverse.find( self.first_verse )
      else
        initial_mv = self
      end
      
      x = initial_mv
      
      # Find the first verse that is overdue or hasn't been tested within the minimum test frequency window
      # TODO: do we want to return a verse that was tested today as 'due' ?
      while (x.next_test > Date.today + slack) and (Date.today - x.last_tested < min_test_freq) and x.next_verse
        x = Memverse.find(x.next_verse)   
      end   
      
      return x
    end
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Is there anything else to memorize in this sequence or can we move on
  # Input: memverse_id (can be a single verse or any verse in a sequence)
  # Returns: true if there are more verses to memorize downstream in a sequence
  # TODO: find a way to skip long memorized sections
  # ----------------------------------------------------------------------------------------------------------   
  def more_to_memorize_in_sequence?
    
    slack         =  7 # Add some slack to avoid having to review the entire sequence too soon afterwards
    min_test_freq = 60 # Minimum test frequency in days for entire sequence     
    
    if self.solo_verse? or self.next_verse.nil?
      return false
    else
      
      x = Memverse.find(self.next_verse)
      
      while (x.next_test > Date.today + slack) and (Date.today - x.last_tested < min_test_freq) and x.next_verse
        x = Memverse.find(x.next_verse)   
      end         
      
      # After the preceding loop we have found either a verse that needs to be memorized or 
      # we're at the last verse of the sequence
      # First condition: verse is overdue and needs testing
      # Second condition: verse hasn't been tested recently enough and needs testing 
      return !((x.next_test > Date.today + slack) and (Date.today - x.last_tested < min_test_freq))
        
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Checks whether verse is locked
  # Input:  A verse ID
  # Output: True/False depending on whether verse is/isn't locked
  # ----------------------------------------------------------------------------------------------------------  
  def locked?
    return self.verse.locked?
  end   

  # ----------------------------------------------------------------------------------------------------------
  # Checks whether verse is locked
  # Input:  A verse ID
  # Output: True/False depending on whether verse is/isn't locked
  # ----------------------------------------------------------------------------------------------------------  
  def verified?
    return self.verse.verified?
  end  


  # ----------------------------------------------------------------------------------------------------------
  # Input: memverse_id
  # Returns: TRUE if verse is not part of a sequence
  # ----------------------------------------------------------------------------------------------------------   
  def solo_verse?
    if !self.prev_verse and !self.next_verse
      return true
    else
      return false
    end
  end
  
  def needs_mnemonic?
    return case self.user.mnemonic_use
      when "Never"  then false
      when "Always" then true
      when "Learning" then self.test_interval < 7
    end
  end
  
  def all_user_tags
    self.verse.all_user_tags
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Find the next/prev verse in the users list ... used to step through verses when tagging
  # ----------------------------------------------------------------------------------------------------------     
  def next_verse_in_user_list
    
    u           = self.user
    all_verses  = u.memverses.all(:include => :verse).sort!
    
    position    = all_verses.index(self)
    return all_verses[position+1] || all_verses[0]
  end
  
  def prev_verse_in_user_list
    
    u           = self.user
    all_verses  = u.memverses.all(:include => :verse).sort!
    
    position    = all_verses.index(self)
    return all_verses[position-1]
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Retrieve previous/next memory verse NOTE: Replacement for method in application_controller.rb
  #   Input: verse_id
  #   Output: mv_id
  # ----------------------------------------------------------------------------------------------------------   
  def get_prev_verse

    book    = self.verse.book
    chapter = self.verse.chapter.to_i
    verse   = self.verse.versenum.to_i
    transl  = self.verse.translation

    # Check for 2 conditions
    #   previous verse is in db
    #   and prev_verse is in user's list of memory verses  
    if (prev_vs = Verse.exists_in_db(book, chapter, verse-1, transl)) and prev_mv = self.user.has_verse_id?(prev_vs) 
      return prev_mv.id 
    else
      return nil
    end   
  end
  
  def get_next_verse

    book    = self.verse.book
    chapter = self.verse.chapter.to_i
    verse   = self.verse.versenum.to_i
    transl  = self.verse.translation

    # Check for 2 conditions
    #   previous verse is in db
    #   and prev_verse is in user's list of memory verses  
    if (next_vs = Verse.exists_in_db(book, chapter, verse+1, transl)) and next_mv = self.user.has_verse_id?(next_vs) 
      return next_mv.id 
    else
      return nil
    end 
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return first verse in a series but does not use any of the linkage stored in the DB
  #   Input:  mv_id
  #   Output: mv_id or nil if no first verse
  # ----------------------------------------------------------------------------------------------------------
  def get_first_verse
    
    book    = self.verse.book
    chapter = self.verse.chapter.to_i
    verse   = self.verse.versenum.to_i
    transl  = self.verse.translation
    
    # TODO -- this has been hacked out ... check VERY CAREFULLY
    while (prev_vs = Verse.exists_in_db(book, chapter, verse-1, transl)) and prev_mv = self.user.has_verse_id?(prev_vs)
      verse = verse-1
      first_verse = prev_mv
    end
    
    return first_verse ? first_verse.id : nil
    
  end

  # ============= Protected below this line ==================================================================
  protected
  
end