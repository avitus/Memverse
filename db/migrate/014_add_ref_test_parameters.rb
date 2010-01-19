class AddRefTestParameters < ActiveRecord::Migration
  def self.up
     
    add_column :memverses, :ref_interval,   :integer, :default => 1
    add_column :memverses, :next_ref_test,  :date

  end

  def self.down
    
    remove_column :memverses, :ref_interval, :next_ref_test
    
  end
  
end
