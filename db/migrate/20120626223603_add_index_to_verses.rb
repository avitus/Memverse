class AddIndexToVerses < ActiveRecord::Migration[7.0]
  def change
    add_index :verses, [:translation, :book, :chapter, :versenum], :unique => true
  end
end
