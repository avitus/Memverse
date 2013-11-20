class Uberverse < ActiveRecord::Base
  has_many :sermons
  has_many :quiz_questions, :foreign_key => "supporting_ref"

  # ----------------------------------------------------------------------------------------------------------
  # Outputs friendly verse reference: eg. "Jn 3:16"
  # ----------------------------------------------------------------------------------------------------------
  def ref
    book_tl = I18n.t abbr(book).to_sym, :scope => [:book, :abbrev]
    return book_tl + ' ' + chapter.to_s + ':' + versenum.to_s
  end

  # ----------------------------------------------------------------------------------------------------------
  # Outputs friendly verse reference: eg. "John 3:16"
  # ----------------------------------------------------------------------------------------------------------
  def long_ref
    book_tl = I18n.t book.to_sym, :scope => [:book, :name]
    return book_tl + ' ' + chapter.to_s + ':' + versenum.to_s
  end

  # ============= Protected below this line ==================================================================
  protected

  # ----------------------------------------------------------------------------------------------------------
  # Abbreviates book names
  # Input:  'Deuteronomy'
  # Output: 'Deut'
  # ----------------------------------------------------------------------------------------------------------
  def abbr(book)
    return BIBLEABBREV[book_index(book)-1]
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns bible book index
  # Input:  'Deuteronomy' or 'Deut'
  # Output: 5 or nil if book doesn't exist
  # Note: This breaks if string is not a valid book because you can't add 1 + nil
  # Note: The last check is required to handle 'Song of Songs' because titleizing it becomes "Song Of Songs"
  # ----------------------------------------------------------------------------------------------------------
  def book_index(str=self.book)
    if x = (BIBLEBOOKS.index(str.titleize) || BIBLEABBREV.index(str.titleize) || BIBLEBOOKS.index(str))
      return 1+x
    else
      return nil
    end
  end

end
