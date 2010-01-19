class AddUserProfile < ActiveRecord::Migration
  def self.up
    add_column :users, :last_reminder, :date
    add_column :users, :reminder_freq, :string,  :default => "weekly"
    add_column :users, :newsletters,   :boolean, :default => true  
  end

  def self.down
    remove_column :memverses, :last_reminder
    remove_column :memverses, :reminder_freq
    remove_column :memverses, :newsletters 
  end
end