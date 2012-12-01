class Passage < ActiveRecord::Base

  belongs_to :user

  has_many   :memverses
  has_many   :verses, :through => :memverses

  validates_presence_of   :user_id, :length, :book, :chapter, :first_verse, :last_verse

  attr_accessible :user_id, :book, :chapter, :first_verse, :last_verse, :efactor, :last_tested, :length, :next_test, :reference, :rep_n, :test_interval


  # ----------------------------------------------------------------------------------------------------------
  # Combine two passages into one
  # ----------------------------------------------------------------------------------------------------------
  def combine_with( second_passage )

    self.first_verse = [self.first_verse, second_passage.first_verse].min
    self.last_verse  = [self.last_verse,  second_passage.last_verse ].max
    self.length      = self.last_verse - self.first_verse + 1

    # Associate all memory verses from second passage with this passage
    second_passage.memverses.each { |mv| mv.update_attribute( :passage_id, self.id ) }

    # Delete second passage
    second_passage.destroy

  end

end
