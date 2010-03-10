class AddMemverseIndexes < ActiveRecord::Migration
  def self.up
      
    add_index :memverses, :user_id
    add_index :memverses, :verse_id
 
  end

  def self.down
    
    add_index :memverses, :user_id
    add_index :memverses, :verse_id
    
  end
  
end
