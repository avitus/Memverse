class AddLockToVerse < ActiveRecord::Migration
 
  def self.up
    add_column :verses, :verified, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :verses, :verified
  end
  
end
