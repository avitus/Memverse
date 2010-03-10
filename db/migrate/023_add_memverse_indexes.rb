class AddMemverseIndexes < ActiveRecord::Migration
  def self.up
      
    add_index :memverses,         :user_id
    add_index :memverses,         :verse_id
    add_index :progress_reports,  :user_id
     
  end

  def self.down
    
    remove_index :memverses,        :user_id
    remove_index :memverses,        :verse_id
    remove_index :progress_reports, :user_id
    
  end
  
end
