class AddCheckedByToVerse < ActiveRecord::Migration
 
  def self.up
    add_column :verses, :checked_by, :string
  end

  def self.down
    remove_column :verses, :checked_by
  end
  
end
