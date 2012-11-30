class Passage < ActiveRecord::Base

  belongs_to :user

  has_many   :memverses
  has_many   :verses, :through => :memverses

  validates_presence_of   :user_id, :length, :book, :chapter, :first_verse, :last_verse

  attr_accessible :user_id, :book, :chapter, :first_verse, :last_verse, :efactor, :last_tested, :length, :next_test, :reference, :rep_n, :test_interval


end
