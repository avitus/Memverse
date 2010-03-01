class AddUserAccuracy < ActiveRecord::Migration
 
  def self.up
    add_column :users, :accuracy, :integer, :default => 50   
  end

  def self.down
    remove_column :users, :accuracy
  end
  
end
