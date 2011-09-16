class FinalVerse < ActiveRecord::Base

  
  # Validations
  validates_presence_of :book, :chapter, :last_verse

  protected
  
end