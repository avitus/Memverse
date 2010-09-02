class AddVerseIndexes < ActiveRecord::Migration
  def self.up
    
    add_index :verses,  :book
    add_index :verses,  :chapter
    add_index :verses,  :versenum
    add_index :verses,  :translation
     
  end

  def self.down
 
    remove_index :verses,  :book
    remove_index :verses,  :chapter
    remove_index :verses,  :versenum
    remove_index :verses,  :translation    

  end
  
end
