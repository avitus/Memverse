class AddMemverseUniquenessIndex < ActiveRecord::Migration
 
  def self.up
    add_index  :memverses, [:user_id, :verse_id], :unique => true
  end

  def self.down
    remove_index  :memverses, [:user_id, :verse_id]
  end
  
end
