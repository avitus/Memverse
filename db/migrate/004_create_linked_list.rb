class CreateLinkedList < ActiveRecord::Migration
  def self.up
    add_column :memverses, :first_verse, :integer
    add_column :memverses, :prev_verse, :integer
    add_column :memverses, :next_verse, :integer    
  end

  def self.down
    remove_column :memverses, :first_verse
    remove_column :memverses, :prev_verse
    remove_column :memverses, :next_verse 
  end
end