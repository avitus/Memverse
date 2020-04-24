class AddBookIndexToPassages < ActiveRecord::Migration

  def book_index(str)
    if x = (BIBLEBOOKS.index(str.titleize) || BIBLEABBREV.index(str.titleize) || BIBLEBOOKS.index(str))
      return 1+x
    else
      return nil
    end
  end

  class Passage < ActiveRecord::Base
  end

  def change
    add_column :passages, :book_index, :integer
    add_index :passages, :book_index
    Passage.reset_column_information
    Passage.find_each { |p| p.update_attributes!( book_index: book_index(p.book) ) }
  end
end
