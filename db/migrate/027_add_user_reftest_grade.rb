class AddUserReftestGrade < ActiveRecord::Migration
 
  def self.up
    add_column :users, :ref_grade, :integer, :default => 10   
  end

  def self.down
    remove_column :users, :ref_grade
  end
  
end