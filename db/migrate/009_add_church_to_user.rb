class AddChurchToUser < ActiveRecord::Migration
 
  def self.up
    add_column :users, :church, :string 
  end

  def self.down
    remove_column :users, :church 
  end
  
end
