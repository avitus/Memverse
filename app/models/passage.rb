class Passage < ActiveRecord::Base

  belongs_to :user

  has_many   :memverses
  has_many   :verses, :through => :memverses

  attr_accessible :book, :chapter, :first_verse, :last_verse, :efactor, :last_tested, :length, :next_test, :reference, :rep_n, :test_interval



end
