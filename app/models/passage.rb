class Passage < ActiveRecord::Base

  belongs_to :user

  has_many   :memverses
  has_many   :verses, :through => :memverses

  attr_accessible :efactor, :first_verse, :last_tested, :length, :next_test, :reference, :rep_n, :test_interval

end
