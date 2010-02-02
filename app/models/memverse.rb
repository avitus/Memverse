class Memverse < ActiveRecord::Base
  
  #    t.integer  "user_id",                                                      :null => false
  #    t.integer  "verse_id",                                                     :null => false
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
  
  # Relationships
  belongs_to  :user
  belongs_to  :verse
  
  # Named Scopes
  named_scope :memorized, :conditions => { :status => "Memorized" }
  named_scope :learning, :conditions => { :status => "Learning" }
  named_scope :current, lambda { {:conditions => ['next_test >= ?', Date.today ]} }
  named_scope :american, :include => {:user, :country}, :conditions => { 'countries.printable_name' => 'United States' }
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
  # Sort Memory Verse objects according to biblical book order
  # Input: 
  # Returns: 
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
    if prev_vs = Verse.exists_in_db(book, chapter, verse-1, transl) and prev_mv = self.user.has_verse_id?(prev_vs) 
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
    if next_vs = Verse.exists_in_db(book, chapter, verse+1, transl) and next_mv = self.user.has_verse_id?(next_vs) 
      return next_mv.id 
    else
      return nil
    end 
  end

  def get_first_verse
    # TODO -- need to implement this
  end

  # ============= Protected below this line ==================================================================
  protected
  
end