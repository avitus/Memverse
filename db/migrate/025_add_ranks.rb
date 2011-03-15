class AddRanks < ActiveRecord::Migration
 
  def self.up
    add_column :users,            :rank, :integer, :default => nil
    add_column :churches,         :rank, :integer, :default => nil
    add_column :american_states,  :rank, :integer, :default => nil
    add_column :countries,        :rank, :integer, :default => nil
    
  end

  def self.down
    remove_column :users,           :rank
    remove_column :churches,        :rank
    remove_column :american_states, :rank
    remove_column :countries,       :rank
  end
  
end
