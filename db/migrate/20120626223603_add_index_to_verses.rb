class AddIndexToVerses < ActiveRecord::Migration
  def change
    add_index :verses, [:translation, :book, :chapter, :versenum], :unique => true
  end
end
