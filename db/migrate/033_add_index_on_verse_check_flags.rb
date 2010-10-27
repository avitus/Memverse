class AddIndexOnVerseCheckFlags < ActiveRecord::Migration
  def self.up
      
    add_index :verses,         :verified
    add_index :verses,         :error_flag
     
  end

  def self.down
    
    remove_index :verses,      :verified
    remove_index :verses,      :error_flag
    
  end
  
end
