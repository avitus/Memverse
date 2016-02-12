class Memverse < ActiveRecord::Base

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :Memverse do
    key :required, [:verse_id, :user_id ]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :verse_id do
      key :type, :integer
      key :format, :int64
    end
    property :user_id do
      key :type, :integer
      key :format, :int64
    end    
    property :efactor do
      key :type, :number
    end 
    property :test_interval do
      key :type, :integer
      key :format, :int64
    end 
    property :rep_n do
      key :type, :integer
      key :format, :int64
    end 
    property :next_test do
      key :type, :string
      key :format, :date
    end 
    # property :last_tested do
    #   key :type, :string
    #   key :format, :date
    # end 
    property :status do
      key :type, :string
    end 
    # property :attempts do
    #   key :type, :integer
    #   key :format, :int64
    # end    
    # property :created_at do
    #   key :type, :string
    #   key :format, :dateTime
    # end 
    # property :updated_at do
    #   key :type, :string
    #   key :format, :dateTime
    # end 
    # property :first_verse do
    #   key :type, :integer
    #   key :format, :int64
    # end  
    property :prev_verse do
      key :type, :integer
      key :format, :int64
    end  
    # property :next_verse do
    #   key :type, :integer
    #   key :format, :int64
    # end
    property :ref_interval do
      key :type, :integer
      key :format, :int64
    end    
    property :next_ref_test do
      key :type, :string
      key :format, :date
    end
    # property :uberverse_id do
    #   key :type, :integer
    #   key :format, :int64
    # end
    property :passage_id do
      key :type, :integer
      key :format, :int64
    end
    property :subsection do
      key :type, :integer
      key :format, :int64
    end          
  end

  swagger_schema :MemverseInput do
    allOf do
      schema do
        key :'$ref', :Memverse
      end
      schema do
        key :required, [:id]
        property :id do
          key :type, :integer
          key :format, :int64
        end
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------

  acts_as_taggable # Alias for acts_as_taggable_on :tags

  # Relationships
  belongs_to :user
  belongs_to :verse
  belongs_to :passage

  has_one :country, :through => :user

  # Named Scopes
  scope :memorized,     -> { where(status: "Memorized") }
  scope :learning,      -> { where(status: "Learning" ) }

  scope :active,        -> { where(status: ["Learning", "Memorized"]) }
  scope :inactive,      -> { where(status: "Pending") }

  scope :not_due,       -> { where("next_test  > ?", Date.today) }
  scope :current,       -> { where("next_test >= ?", Date.today) }
  scope :due_today,     -> { where("next_test  = ?", Date.today) }
  scope :overdue,       -> { where("next_test  < ?", Date.today) }

  # We need to check for nil values because that column has no default value
  scope :ref_due,       -> { where("next_ref_test IS NULL or next_ref_test <= ?", Date.today) }

  scope :passage_start, -> { where(prev_verse: nil) }

  scope :american,      -> { joins(:user, :country).where("countries.name" => "United States") }

  scope :old_testament, -> { where("verses.book_index" =>  1..39).includes(:verse) }
  scope :new_testament, -> { where("verses.book_index" => 40..66).includes(:verse) }

  scope :history,  -> { where("verses.book_index BETWEEN 1 AND 17 OR verses.book_index = 44").includes(:verse) }
  scope :wisdom,   -> { where("verses.book_index" => 18..22).includes(:verse) }
  scope :prophecy, -> { joins(:verse).where("verses.book_index BETWEEN 23 AND 39 OR verses.book_index = 66").includes(:verse) }
  scope :gospel,   -> { where("verses.book_index" => 40..43).includes(:verse) }
  scope :epistle,  -> { where("verses.book_index" => 45..65).includes(:verse) }

  scope :canonical_sort, -> { includes(:verse).order('verses.book_index, verses.chapter, verses.versenum') }

  # Validations
  validates :user_id,  :presence => true
  validates :verse_id, :presence => true, :uniqueness => {:scope => :user_id}

  # Needed to add this for Rails 4
  attr_protected :test_interval

  # Set initial values and link verse other verses
  before_create  :supermemo_init

  # TODO: these should be obsolete now that we have a Passage model.
  after_create   :add_links
  before_destroy :update_links

  # Update counter cache
  after_save    :update_counter_cache
  after_destroy :update_counter_cache

  # Add/remove from passage when creating/deleting memverse
  after_create   :add_to_passage
  before_destroy :remove_from_passage

  # Update related passage
  after_save :update_passage


  # Exposed via API
  def serializable_hash(options = {})
    super only: [:id, :user_id, :next_test, :test_interval, :status, :rep_n, :efactor, :subsection, :prev_verse, :passage_id, :next_ref_test, :ref_interval],
          methods: [:ref],
          include: [verse: {only: [:id, :translation, :text, :versenum]}]
  end

  # Convert to JSON format (for AJAX goodness on main memorization page)
  #
  # @todo Find a way to exclude :skippable when not needed ... too slow otherwise
  #       Actually, with the new passage review we could probably dispense with 'skippable'
  def as_json(options={})
    {
      :id            => self.id,
      :verse_id      => self.verse.id,
      :passage_id    => self.passage.id,
      :ref           => self.verse.ref,
      :tl            => self.verse.translation,
      :text          => self.verse.text,
      :versenum      => self.verse.versenum,
      :next_test     => self.next_test,
      :test_interval => self.test_interval,
      :skippable     => !self.due? ? ( !self.next_verse_due(true).nil? ? self.next_verse_due(true).verse.ref : false ) : false,
      :mnemonic      => self.needs_mnemonic? ? self.verse.mnemonic : "",
      :feedback      => self.show_feedback?,
      :status        => self.status,
      :rep_n         => self.rep_n,
      :efactor       => self.efactor,
      :subsection    => self.subsection,
      :prev_verse    => self.prev_verse    # needed for iOS app
    }
  end

  def ref
    self.verse.ref
  end

  def text
    self.verse.text
  end

  # Implementation of SM-2 algorithm
  #
  # Depends on the following:
  #     q             - result of test
  #     n             - current iteration in learning sequence
  #     interval      - interval in days before next test
  #     efactor       - easiness factor
  #
  #   Q  Change in EF
  #   ~~~~~~~~~~~~~~~~
  #   0     -0.80
  #   1     -0.54
  #   2     -0.32
  #   3     -0.14
  #   4     +0.00
  #   5     +0.10
  #
  # Changes interval and eFactor.
  #
  # @param q [Fixnum] result of test
  # @return [Boolean] true if Memverse changes to "Memorized"
  def supermemo(q)

    prev_learning = (self.status == "Learning")

    if self.due?
      if q<3 # answer was incorrect
        n_new = 1  # Start from the beginning
      else
        n_new = self.rep_n + 1 # Go on to next iteration
      end

      efactor_new = [ self.efactor - 0.8 + (0.28 * q) - (0.02 * q * q), 2.5 ].min # Cap eFactor at 2.5
      if efactor_new < 1.3
        efactor_new = 1.3 # Set minimum efactor to 1.3 (Orig algorithm was 1.3)
      end

      # Calculate new interval
      interval_new = case n_new
        when 1 then 1
        when 2 then 4
        else [self.test_interval * efactor_new, self.user.max_interval.to_i].min.round # Don't set interval to more than one year for now
      end
    else # don't update verses that aren't due
      n_new         = self.rep_n
      interval_new  = self.test_interval
      efactor_new   = self.efactor
    end

    # Update memory verse parameters
    self.rep_n          = n_new
    self.efactor        = efactor_new
    self.test_interval  = [interval_new,1].max
    self.next_test      = Date.today + interval_new
    self.last_tested    = Date.today
    self.status         = interval_new > 30 ? "Memorized" : "Learning"
    self.attempts      += 1
    self.save!

    self.sync_subsection  # Sync with rest of subsection

    return (prev_learning and (self.status == "Memorized"))  # TRUE if this memory verse is newly memorized
  end

  # ----------------------------------------------------------------------------------------------------------
  # Update reference interval
  # ----------------------------------------------------------------------------------------------------------
  def change_ref_interval(recalled)

    if recalled
      self.ref_interval = [ (self.ref_interval * 1.5), self.user.max_interval.to_i ].min.round
    else
      self.ref_interval = [ (self.ref_interval * 0.6), 1 ].max.round
    end

    self.next_ref_test = Date.today + self.ref_interval
    self.save

  end

  # ----------------------------------------------------------------------------------------------------------
  # Return all verses in subsection
  # ----------------------------------------------------------------------------------------------------------
  def entire_subsection
    if self.subsection  # subsection is nil if the passage has not yet been subsectioned
      Memverse.where(passage_id: self.passage_id, subsection: self.subsection)
    else
      nil
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Memory verses from the same subsection that are not due for review today or have already been reviewd
  # ----------------------------------------------------------------------------------------------------------
  def not_due_today_subsection
    if self.subsection  # subsection is nil if the passage has not yet been subsectioned
      Memverse.where(passage_id: self.passage_id, subsection: self.subsection).not_due
    else
      nil
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Is this memory verse part of a subsection (a smaller unit than a passage)?
  # ----------------------------------------------------------------------------------------------------------
  def part_of_subsection?
    !!self.subsection && Memverse.where(passage_id: self.passage_id, subsection: self.subsection).length > 1
  end

  # ----------------------------------------------------------------------------------------------------------
  # Synchronize review of memory verses that are grouped in a subsection
  # ----------------------------------------------------------------------------------------------------------
  def sync_subsection

    if self.user.sync_subsections && self.part_of_subsection?

      subsection_array = self.not_due_today_subsection

      min_test_interval   = subsection_array.minimum(:test_interval)
      earliest_next_test  = subsection_array.minimum(:next_test)
      subsection_status   = min_test_interval > 30 ? "Memorized" : "Learning"

      subsection_array.each do |mv|
        mv.test_interval = [min_test_interval,1].max
        mv.next_test     = Date.today + min_test_interval
        mv.status        = subsection_status
        mv.save!
      end

    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Return length of verse sequence
  # @return [Fixnum] length of memory verse sequence
  def sequence_length
    return 1 if self.solo_verse? # not part of a sequence

    length = 1

    initial_mv = self.first_verse? ? Memverse.find(self.first_verse) : self
    x = initial_mv

    while x.next_verse && x = Memverse.find(x.next_verse)
      length += 1
    end

    return length
  end

  # Update the starting verse for downstream verses -- mostly used when a verse is deleted
  def update_downstream_start_verses
    # If mv is pointing to a start verse, use that as the first verse, otherwise set mv as the first verse
    new_starting_verse = self.first_verse || self.id # || returns first operator that satisfies condition

    mv = self

    while mv.next_verse
      mv = Memverse.find(mv.next_verse)
      mv.first_verse = new_starting_verse
      mv.save
    end
  end

  # Check for users with duplicates
  # @return [Array<User>]
  # @todo Is this method ever used?
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

  # Sort Memory Verse objects according to biblical book order
  # @see Verse#<=>
  # @todo This is slow; DB sort is faster.
  def <=>(o)
    self.verse <=> o.verse
  end

  # Return entire chapter as array
  #
  # @return [Array<Memverse>] Memverses from chapter, sorted by versenum.
  def chapter
    self.part_of_entire_chapter? ? self.passage.memverses.includes(:verse).order('verses.versenum') : nil
  end

  # User has entire chapter: i.e. does user have the last verse in the chapter and is it linked to the 1st verse
  #
  # @return [Boolean]
  def part_of_entire_chapter?

    # @todo This is a problem. We are somehow ending up with memory verses associated with nonexistent passages.
    if !self.passage
      Rails.logger.warn("=====> Memory verse #{self.id} is associated with a nonexistent passage. Adding it to a passage.")
      self.add_to_passage
    end

    return self.passage.complete_chapter

  end

  # User has entire chapter memorized
  #
  # @return [Boolean] True if entire passage memorized; false otherwise
  # (including if user does not have entire chapter in account).
  #
  # @todo Consider returning Array of Boolean values [true, false, false ... ]
  #   if user hasn't memorized entire passage
  def chapter_memorized?
    mvs = self.passage.memverses # ALV 2014-09-03 Occasionally finding memverse record that points to a nonexistent passage

    if self.passage.complete_chapter
      mvs.count == mvs.where(status: "Memorized").count
    else
      false
    end
  end

  # User has entire chapter pending
  #
  # @return [Boolean] True iff user has entire chapter in account, and every verse pending.
  def chapter_pending?
    mvs = self.passage.memverses

    if self.passage.complete_chapter
      mvs.count == mvs.where(status: "Pending").count
    else
      false
    end
  end

  # Is a verse memorized?
  def memorized?
    status == "Memorized"
  end

  # Toggle Memverse: active/inactive
  #
  # @return [String] New status ("Memorized", "Learning", or "Pending")
  def toggle_status
    if status == "Pending"
      self.update(status: (self.test_interval > 30) ? "Memorized" : "Learning")
    else
      self.update(status: "Pending")
    end

    return status
  end

  # Is this the first verse in a sequence or a solo verse ?
  def is_first_verse?
    return !self.prev_verse
  end

  # Is this verse linked to the first verse of a chapter?
  # @todo what should we return if this is the first verse?
  def linked_to_first_verse?
    if self.solo_verse?
      return false
    elsif self.first_verse
      Memverse.find(self.first_verse).verse.versenum.to_i <= 1  # Handles Psalm x:0 case where title is in verse 0
    else
      return false
    end
  end

  # Is a verse due for memorization?
  #
  # @return [Boolean]
  def due?
    return self.next_test <= Date.today
  end

  # Is this verse a prior verse in the same passage
  #
  # @return [Boolean]
  def prior_in_passage_to?(mv)

    if mv && self.passage.id == mv.passage.id  # memory verses are in same passage
      return self.verse.versenum <= mv.verse.versenum
    else
      return false
    end

  end

  # Return first verse in a sequence
  #
  # @return [Memverse]
  def first_verse_in_sequence
    if self.first_verse
      initial_mv = find( self.first_verse )
    else
      initial_mv = self
    end

    return initial_mv

  end

  # Return first overdue verse in a sequence
  #
  # @return [Memverse] First overdue verse (or last verse if no verses are due -- that's acceptable for now
  #          since we're only likely to call this function when we know one of the verses needs review).
  def first_verse_due_in_sequence

    slack         =   7 # Add some slack to avoid having to review the entire sequence too soon afterwards
    min_test_freq = 120 # Minimum test frequency in days for entire sequence

    if self.solo_verse? # not part of a sequence
      return self
    else

      # find the first verse - we don't know whether this is the first verse so need to check
      # @todo Can replace with #first_verse_in_sequence method above (once thoroughly tested)
      if self.first_verse
        initial_mv = Memverse.find( self.first_verse )
      else
        initial_mv = self
      end

      x = initial_mv

      # Find the first verse that is overdue or hasn't been tested within the minimum test frequency window
      # TODO: do we want to return a verse that was tested today as 'due' ?
      while ((x.inactive?) || ((x.next_test > Date.today + slack) && (Date.today - x.last_tested < min_test_freq))) and x.next_verse
        x = Memverse.find(x.next_verse)
      end

      return x
    end
  end

  # Returns the next verse that is due in a sequence
  #
  # @return [Memverse, nil] next memory verse due in the passage or nil
  def next_verse_due_in_sequence

    if self.solo_verse? || self.next_verse.nil?
      return nil
    else
      x = Memverse.find(self.next_verse)

      while ((x.inactive?) || (x.next_test > Date.today)) and x.next_verse
        x = Memverse.find(x.next_verse)
      end

      if (x.next_test <= Date.today) && (x.status != 'Pending')
        return x
      else
        return nil
      end
    end
  end

  # Returns the next verse that is active due in a sequence
  # @return [Memverse, nil] the next memory verse active in the passage or nil
  def next_verse_active_in_sequence

    if self.solo_verse? || self.next_verse.nil?
      return nil
    else
      x = Memverse.find(self.next_verse)

      while x.inactive? && x.next_verse
        x = Memverse.find(x.next_verse)
      end

      if x.active?
        return x
      else
        return nil
      end
    end
  end

  # Is there anything else to memorize in this sequence or can we move on
  #
  # @return [Boolean] true if there are more verses to memorize downstream in a sequence
  def more_to_memorize_in_sequence?

    slack         =  7 # Add some slack to avoid having to review the entire sequence too soon afterwards
    min_test_freq = self.user.max_interval || 120 # Minimum test frequency in days for entire sequence

    if self.solo_verse? || self.next_verse.nil?
      return false
    else

      x = Memverse.find(self.next_verse)

      while ((x.status == 'Pending') || ((x.next_test > Date.today + slack) && (Date.today - x.last_tested < min_test_freq))) and x.next_verse
        x = Memverse.find(x.next_verse)
      end

      # After the preceding loop we have found either a verse that needs to be memorized or
      # we're at the last verse of the sequence
      # 1st condition: verse is pending
      # 2nd condition: verse is overdue and needs testing
      # 3rd condition: verse hasn't been tested recently enough and needs testing
      return !(((x.status == 'Pending') || ((x.next_test > Date.today + slack) && (Date.today - x.last_tested < min_test_freq))))

    end
  end

  # Checks whether verse is locked
  #
  # @return [Boolean]
  def locked?
    verse.locked?
  end

  # Checks whether verse is verified
  #
  # @return [Boolean]
  def verified?
    verse.verified?
  end

  # Checks whether verse is active (status not "Pending")
  #
  # @return [Boolean]
  def active?
    status != "Pending"
  end

  # Checks whether verse is inactive (status: "Pending")
  #
  # @return [Boolean]
  def inactive?
    status == "Pending"
  end

  # Not part of sequence?
  #
  # @return [Boolean] true if memory verse is not part of a sequence
  def solo_verse?
    return !prev_verse && !next_verse
  end

  # Should mnemonic display?
  #
  # @return [Boolean] depending on whether user wants Mnemonic support, verse is memorized etc.
  def needs_mnemonic?
    return case user.mnemonic_use
      when "Never"    then false
      when "Always"   then true
      when "Learning" then self.test_interval < 7
    end
  end

  # Show mnemonic if required
  #
  # @return [String] Either mnemonic or "-" (when not required)
  def mnemonic_if_req
    self.needs_mnemonic? ? self.verse.mnemonic : "-"
  end

  # Show feedback for memory verse?
  #
  # @return [Boolean]
  def show_feedback?
    test_interval < 90 || self.user.show_echo?
  end

  # List of all the tags for the associated verse
  #
  # @return [Array<ActsAsTaggableOn::Tag>]
  def all_user_tags
    self.verse.all_user_tags
  end

  # Find the next verse in the user's list
  # Used to step through verses when tagging
  # @todo Optimize queries (this and #prev_verse_in_user_list); should be able to do it without selecting all of user's verses.
  def next_verse_in_user_list

    u           = self.user
    all_verses  = u.memverses.canonical_sort

    position    = all_verses.index(self)
    return all_verses[position+1] || all_verses[0]
  end

  # Find the prev verse in the user's list
  # Used to step through verses when tagging
  def prev_verse_in_user_list

    u           = self.user
    all_verses  = u.memverses.canonical_sort

    position    = all_verses.index(self)
    return all_verses[position-1]
  end

  # Find a verse that is due but not this one
  def another_due_verse
    mv = user.memverses.where("id != ?", self.id).active.order("next_test ASC").first

    if mv && mv.due?
      return mv.first_verse_due_in_sequence
    else
      return nil
    end
  end

  # Return the next verse that needs to be memorized today [AJAX]
  # @see User#first_verse_today `User` companion method (`first_verse_today`)
  def next_verse_due(skip = false)
    # If part of passage, and there is an active verse downstream
    # then return next verse in passage
    # unless user wants to skip to the next verse that is due
    if self.next_verse && self.more_to_memorize_in_sequence?

      if skip
        # try next verse due in passage, else return another verse due
        return self.next_verse_due_in_sequence || self.another_due_verse
      else
        # return next active verse in passage, else return another verse due
        return self.next_verse_active_in_sequence || self.another_due_verse
      end

    end

    return self.another_due_verse

  end

  # Retrieve previous memory verse
  # @note Replacement for method in application_controller.rb
  # @return [Fixnum] Memverse ID
  def get_prev_verse

    book    = self.verse.book
    chapter = self.verse.chapter.to_i
    verse   = self.verse.versenum.to_i
    transl  = self.verse.translation

    # Check for 2 conditions
    #   previous verse is in db
    #   and prev_verse is in user's list of memory verses
    if (prev_vs = Verse.exists_in_db(book, chapter, verse-1, transl)) && prev_mv = self.user.has_verse_id?(prev_vs)
      return prev_mv.id
    else
      return nil
    end
  end

  # Retrieve next memory verse
  # @note Replacement for method in application_controller.rb
  # @return [Fixnum] Memverse ID
  def get_next_verse

    book    = self.verse.book
    chapter = self.verse.chapter.to_i
    verse   = self.verse.versenum.to_i
    transl  = self.verse.translation

    # Check for 2 conditions
    #   next verse is in db
    #   and next verse is in user's list of memory verses
    if (next_vs = Verse.exists_in_db(book, chapter, verse+1, transl)) && next_mv = self.user.has_verse_id?(next_vs)
      return next_mv.id
    else
      return nil
    end
  end

  # Return previous memory verse
  # @return [Memverse]
  def prior_mv
    self.prev_verse ? Memverse.find(self.prev_verse) : nil
  end

  # Return first verse in a series but does not use any of the linkage stored in the DB
  #
  # @return [Fixnum] Memverse ID or `nil` (if no first verse)
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

  # Add a memory verse to a passage [hook: after_create]
  # @todo Temporarily not protected in order to run rake task
  # Passages cannot straddle chapter boundaries
  def add_to_passage
    vs = self.verse

    # Check for adjacent passages
    prior_passage = Passage.where(:user_id => self.user.id, :book => vs.book, :chapter => vs.chapter, :last_verse  => vs.versenum-1).first
    next_passage  = Passage.where(:user_id => self.user.id, :book => vs.book, :chapter => vs.chapter, :first_verse => vs.versenum+1).first

    # Case 1 - No existing passage
    if !prior_passage && !next_passage
      psg = Passage.create!( :user_id => self.user.id, :translation => vs.translation, :length => 1,
                             :book => vs.book, :chapter => vs.chapter, :first_verse => vs.versenum, :last_verse => vs.versenum )
      self.update_attribute( :passage_id, psg.id )

    # Case 2 - Verse is between two passages -> merge passages
    elsif prior_passage && next_passage
      prior_passage.absorb( next_passage, self )

    # Case 3 - Verse is new first verse of existing passage
    elsif next_passage
      next_passage.expand( self )

    # Case 4 - Verse is new last verse of existing passage
    elsif prior_passage
      prior_passage.expand( self )

    # Shouldn't ever arrive here
    else

    end

  end

  # Remove a memory verse from a passage [hook: before_delete]
  def remove_from_passage

    # Do we need to add a transaction lock here. If both verses in a two verse passage are simultaneously deleted then
    # passage could be stranded as an empty passage. Not to mention all the other corner cases.
    psg = self.passage

    if psg

      # Case 1 - Single verse passage (Note: the second condition accounts for cases where the passage length
      #          is incorrect but this is the last remaining verse)
      if psg.length == 1 or psg.memverses.count == 1

        psg.destroy

      else

        # Case 2 - First verse of passage
        if psg.first_verse == self.verse.versenum

          psg.first_verse += 1
          psg.length -= 1
          psg.update_ref
          psg.consolidate_supermemo
          psg.entire_chapter_flag_check

        # Case 3 - Last verse of passage
        elsif psg.last_verse == self.verse.versenum

          psg.last_verse -= 1
          psg.length -= 1
          psg.update_ref
          psg.consolidate_supermemo
          psg.entire_chapter_flag_check

        # Case 4 - In middle of passage ... need to split passage into two
        else

          memverses_in_passage = psg.memverses.includes(:verse).order('verses.versenum')

          # create new passage for second half of passage
          new_psg = Passage.create!( :user_id => psg.user_id, :translation => psg.translation,
                                     :length =>  psg.last_verse - self.verse.versenum,
                                     :book => psg.book, :chapter => psg.chapter,
                                     :first_verse => self.verse.versenum + 1, :last_verse => psg.last_verse )
          new_psg.update_ref
          new_psg.consolidate_supermemo
          new_psg.entire_chapter_flag_check
          new_psg.save

          # shorten existing passage
          psg.last_verse = self.verse.versenum - 1
          psg.length     = psg.last_verse - passage.first_verse + 1
          psg.update_ref
          psg.consolidate_supermemo
          psg.entire_chapter_flag_check

          # update memverses comprising the new passage
          second_half_of_passage = memverses_in_passage[-(new_psg.length)..(-1)]
          second_half_of_passage.each { |mv| mv.update_attribute( :passage_id, new_psg.id ) }

        end

        psg.save

      end
    end
  end


  # ============= Protected below this line ==================================================================
  protected

  # Initialize new memory verse [hook: before_create]
  def supermemo_init
    self.efactor      = 2.0
    self.last_tested  = Date.today
    self.next_test    = Date.today
    self.status       = self.user.overworked? ? "Pending" : "Learning"

    # Add multi-verse linkage
    # NOTE: ACW commented out to see if this was causing some kind of caching such that add_links wasn't working
    # self.prev_verse   = self.get_prev_verse
    # self.next_verse   = self.get_next_verse
    # self.first_verse  = self.get_first_verse
  end

  # Add links from other verses [hook: after_create]
  def add_links

    # Adding inbound links
    if self.prev_verse ||= self.get_prev_verse  # Attempt to fix race condition
      prior_vs             = Memverse.find(self.prev_verse)
      prior_vs.next_verse  = self.id
      prior_vs.save!

      self.first_verse ||= self.get_first_verse # Attempt to fix race condition
      self.save!                                # Attempt to fix race condition

    end

    if self.next_verse ||= self.get_next_verse  # Attempt to fix race condition
      subs_vs             = Memverse.find(self.next_verse)
      subs_vs.prev_verse  = self.id
      subs_vs.first_verse = self.first_verse || self.id
      subs_vs.save!

      # Updating starting point for downstream verses
      subs_vs.update_downstream_start_verses
      self.save!                                # Attempt to fix race condition
    end

  end

  # Update surrounding links before destroying a memory verse [hook: before_destroy]
  def update_links
    next_ptr  = self.next_verse
    prev_ptr  = self.prev_verse

    # If there is a prev verse
    # => Find previous verse and remove its 'next' ptr
    if prev_ptr
      # TODO: This find method is necesary rather than .find(prev_ptr) for the case (which shouldn't ever happen)
      # when the next/prev pointers aren't valid
      prev_vs = Memverse.where(:id => prev_ptr).first
      if prev_vs
        prev_vs.next_verse = nil
        prev_vs.save
      else
        # TODO: This is occasionally happening ... caused by verses being duplicated from double-clicking on links
        logger.warn("*** Alert: A verse was deleted which had an invalid prev pointer - this should never happen")
      end

    end

    # If there is a next verse
    # => Find next verse and make it the first verse in the sequence
    if next_ptr
      next_vs = Memverse.where(:id => next_ptr).first
      if next_vs
        next_vs.first_verse = nil # Starting verses in a sequence to not reference themselves as the first verse
        next_vs.prev_verse  = nil
        next_vs.save
        # Follow chain and correct first verse
        next_vs.update_downstream_start_verses
      else
        logger.warn("*** Alert: A verse was deleted which had an invalid next pointer - this should never happen")
      end
    end
  end

  # Implement counter caches for number of verses memorized and learning [hook: after_save, after_destroy]
  def update_counter_cache

    u  = self.user
    vs = self.verse

    u.memorized          = u.memverses.memorized.count
    u.learning           = u.memverses.learning.count
    u.last_activity_date = Date.today
    u.save

    vs.memverses_count   = vs.memverses.count
    vs.save

  end

  # Update associated passage [hook: after_save]
  def update_passage
    psg = self.passage
    psg.consolidate_supermemo unless !psg
  end

end
