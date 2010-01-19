class CreateVerses < ActiveRecord::Migration
  def self.up
    # Create Verses Table
    create_table :verses do |t|
      t.string    :translation, :null => false
      t.integer   :book_index,  :null => false
      t.string    :book,        :null => false
      t.string    :chapter,     :null => false
      t.string    :versenum,    :null => false      
      t.text      :text
      t.timestamps
    end
    
    # Create Memory Verses Table
    create_table  :memverses do |t|
      t.integer   :user_id,     :null => false
      t.integer   :verse_id,    :null => false
      t.decimal   :efactor,     :precision =>  5, :scale => 1, :default =>  0.0
      t.integer   :interval,    :default => 1
      t.integer   :rep_n,       :default => 1
      t.date      :next_test
      t.date      :last_tested
      t.string    :status
      t.integer   :attempts,    :default => 0
      t.timestamps
    end    
  end

  def self.down
    drop_table :verses
    drop_table :memverses
  end
end
