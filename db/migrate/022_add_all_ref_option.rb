class AddAllRefOption < ActiveRecord::Migration
 
  def self.up
    add_column :users, :all_refs, :boolean, :default => true   
  end

  def self.down
    remove_column :users, :all_refs
  end
  
end
