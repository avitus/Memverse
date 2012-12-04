class Passage < ActiveRecord::Base

  belongs_to :user

  has_many   :memverses
  has_many   :verses, :through => :memverses

  validates_presence_of   :user_id, :length, :book, :chapter, :first_verse, :last_verse

  attr_accessible :user_id, :book, :chapter, :first_verse, :last_verse, :efactor, :last_tested, :length, :next_test, :reference, :rep_n, :test_interval


  # ----------------------------------------------------------------------------------------------------------
  # Combine two passages into one. Method accepts an optional join (linking) verse
  # ----------------------------------------------------------------------------------------------------------
  def absorb( second_passage, join_mv=nil )

    self.first_verse = [self.first_verse, second_passage.first_verse].min
    self.last_verse  = [self.last_verse,  second_passage.last_verse ].max
    self.length      = self.last_verse - self.first_verse + 1  # uses values calculated in prior two lines

    consolidate_supermemo
    update_ref
    save

    # Associate all memory verses from second passage with this passage
    second_passage.memverses.each { |mv| mv.update_attribute( :passage_id, self.id ) }
    join_mv.update_attribute( :passage_id, self.id ) unless !join_mv

    # Delete second passage
    second_passage.destroy

  end

  # ----------------------------------------------------------------------------------------------------------
  # Add a memory verse into a passage
  # ----------------------------------------------------------------------------------------------------------
  def expand( mv )

    self.first_verse = [ self.first_verse, mv.verse.versenum ].min
    self.last_verse  = [ self.last_verse,  mv.verse.versenum ].max
    self.length += 1

    consolidate_supermemo
    update_ref
    save

    # Associate memory verse with passage
    mv.update_attribute( :passage_id, self.id )

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
    self.test_interval = self.memverses.minimum(:test_interval)
    self.rep_n         = self.memverses.minimum(:rep_n)
    self.efactor       = self.memverses.average(:efactor)
    save
  end

end
