class GetEsv07Started < ActiveRecord::Migration[7.0]
  def up
    verses = Verse.where(:translation => "ESV")
    for verse in verses
      Verse.new(
        :translation => "ESV07",
        :book_index  => verse.book_index,
        :book        => verse.book,
        :chapter     => verse.chapter,
        :versenum    => verse.versenum,
        :text        => verse.text
      ).save
    end
  end

  def down
  end
end
