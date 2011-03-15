class AddFeedbackToggleToUser < ActiveRecord::Migration
 
  def self.up
    add_column :users, :show_echo, :boolean, :default => true
  end

  def self.down
    remove_column :users, :show_echo
  end
  
end
