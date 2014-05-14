class Passage < ActiveRecord::Base

  acts_as_paranoid # soft-deletion

  belongs_to :user

  has_many   :memverses
  has_many   :verses, :through => :memverses

  validates_presence_of   :user_id, :length, :book, :chapter, :first_verse, :last_verse

  attr_protected :test_interval

  scope :due,    -> { where('passages.next_test  <= ?', Date.today) }
  scope :active, -> { joins(:memverses).merge(Memverse.active).group(:id).having('count(memverses.id) > 0') }

  after_create   :update_ref

  # ----------------------------------------------------------------------------------------------------------
  # Convert to JSON format
  # ----------------------------------------------------------------------------------------------------------
  def as_json(options={})
    {
      :id              => self.id,
      :ref             => self.reference,       # TODO: It was a bad idea to rename the attribute
      :interval_array  => self.interval_array
    }

    # It would probably be preferable to handle all 'as_json' using super as far as possible
    # as this would preserve flexibility for the future. That would require using 'reference'
    # rather than 'ref' as we did above. (Only code using ref is in reviewState.Initialize)
    # For now, a complete override as above is ok since we aren't using too many attributes.
    #
    # super(options.reverse_merge(:methods => :interval_array, :only => [:id, :reference]))
  end

  # ----------------------------------------------------------------------------------------------------------
  # Combine two passages into one. Method accepts an optional join (linking) verse.
  #   - Order of join doesn't matter
  # ----------------------------------------------------------------------------------------------------------
  def absorb( second_passage, join_mv=nil )

    self.first_verse = [self.first_verse, second_passage.first_verse].min
    self.last_verse  = [self.last_verse,  second_passage.last_verse ].max
    self.length      = self.last_verse - self.first_verse + 1  # uses values calculated in prior two lines

    # Associate all memory verses from second passage with this passage
    second_passage.memverses.each { |mv| mv.update_attribute( :passage_id, self.id ) }
    join_mv.update_attribute( :passage_id, self.id ) unless !join_mv

    # Delete second passage
    second_passage.destroy

    consolidate_supermemo
    update_ref
    entire_chapter_flag_check
    save!

  end

  # ----------------------------------------------------------------------------------------------------------
  # Add a memory verse into a passage
  # ----------------------------------------------------------------------------------------------------------
  def expand( mv )

    self.first_verse = [ self.first_verse, mv.verse.versenum ].min
    self.last_verse  = [ self.last_verse,  mv.verse.versenum ].max
    self.length += 1

    # Associate memory verse with passage
    mv.update_attribute( :passage_id, self.id )

    consolidate_supermemo
    update_ref
    entire_chapter_flag_check
    save

  end

  # ----------------------------------------------------------------------------------------------------------
  # Update Reference
  # ----------------------------------------------------------------------------------------------------------
  def update_ref

    book = (self.book == "Psalms") ? "Psalm" : self.book;

    if self.length == 1
      self.reference = book + ' ' + self.chapter.to_s + ':' + self.first_verse.to_s
    else
      self.reference = book + ' ' + self.chapter.to_s + ':' + self.first_verse.to_s + '-' + self.last_verse.to_s
    end
    save
    return self.reference
  end

  # ----------------------------------------------------------------------------------------------------------
  # Combine supermemo information from underlying verses
  # ----------------------------------------------------------------------------------------------------------
  def consolidate_supermemo
    self.test_interval = self.memverses.active.minimum(:test_interval)
    self.rep_n         = self.memverses.active.minimum(:rep_n)
    self.last_tested   = self.memverses.active.maximum(:last_tested)
    self.next_test     = self.memverses.active.minimum(:next_test)
    self.efactor       = self.memverses.active.average(:efactor)
    save
  end

  # ----------------------------------------------------------------------------------------------------------
  # Update next_test date
  # ----------------------------------------------------------------------------------------------------------
  def update_next_test_date
    self.next_test     = self.memverses.active.minimum(:next_test)
    save
  end

  # ----------------------------------------------------------------------------------------------------------
  # Set flag if entire chapter has been added to memorization list
  # ----------------------------------------------------------------------------------------------------------
  def entire_chapter_flag_check

    # Corner case for 3 John 1. Not elegant but should usually drop through to primary case
    if book == "3 John" && chapter == 1 && first_verse == 1

      if ["NAS", "NLT", "ESV", "ESV07"].include?( self.translation )
        update_attribute( :complete_chapter, last_verse == 15 )
      else
        update_attribute( :complete_chapter, last_verse == 14 )
      end

    # All other chapters
    else

      # Only look up FinalVerse when first_verse is 1 or 0
      if ( self.first_verse == 1 || self.first_verse == 0 ) && ( self.last_verse == FinalVerse.where(:book => book, :chapter => chapter).first.last_verse )
        update_attribute( :complete_chapter, true )
      else
        update_attribute( :complete_chapter, false )
      end

    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Return array containing the memorization interval of each memverse in passage
  # ----------------------------------------------------------------------------------------------------------
  def interval_array
    self.memverses.pluck(:test_interval)
  end

end
