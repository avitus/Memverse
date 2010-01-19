class AddChurchCounterCache < ActiveRecord::Migration
  def self.up
     
    add_column :churches, :users_count, :integer, :default => 0  
       
    Church.reset_column_information  
    Church.all.each do |c|  
      c.update_attribute :users_count, c.users.length  
    end  
  end

  def self.down
    remove_column :churches, :users_count
  end
  
end
