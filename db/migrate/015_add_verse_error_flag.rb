class AddVerseErrorFlag < ActiveRecord::Migration
  def self.up
     
    add_column :verses, :error_flag, :boolean, :null => false, :default => false

  end

  def self.down
    
    remove_column :verses, :error_flag
    
  end
  
end
