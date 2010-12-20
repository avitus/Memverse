class UserShowToolbar < ActiveRecord::Migration
 
  def self.up
    add_column :users, :show_toolbar, :boolean, :default => true
  end

  def self.down
    remove_column :users, :show_toolbar
  end
  
end
