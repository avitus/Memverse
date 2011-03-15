class AddTimeToProgress < ActiveRecord::Migration
 
  def self.up
    add_column :progress_reports, :time_allocation, :integer   
  end

  def self.down
    remove_column :progress_reports, :time_allocation 
  end
  
end
