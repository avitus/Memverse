class Uberverse < ActiveRecord::Base

  has_many :sermons
  has_many :verses
  has_many :quiz_questions, :foreign_key => "supporting_ref"

  # Outputs friendly verse reference: eg. "Jn 3:16"
  def ref
    "#{Book.find(book_index).abbrev} #{chapter}:#{versenum}"
  end

  # Outputs friendly verse reference: eg. "John 3:16"
  def long_ref
    "#{Book.find(book_index).name} #{chapter}:#{versenum}"
  end

  def major_translations
    return self.verses.where(book: self.book, chapter: self.chapter, versenum: self.versenum,
                          translation: ['NIV', 'ESV', 'NAS', 'NKJ', 'KJV'])
  end

end
