class AddCountryCounterCache < ActiveRecord::Migration
  def self.up
     
    add_column :countries, :users_count, :integer, :default => 0  
       
    Country.reset_column_information  
    Country.all.each do |c|  
      c.update_attribute :users_count, c.users.length  
    end  
  end

  def self.down
    remove_column :countries, :users_count
  end
  
end
