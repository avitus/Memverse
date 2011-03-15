class AddProgressTable < ActiveRecord::Migration
  def self.up
    # Create Progress Table
    create_table :progress_reports do |t|
      
      t.integer   :user_id,     :null => false
      t.date      :entry_date
      t.integer   :learning      
      t.integer   :memorized
    end
     
  end

  def self.down
    drop_table :progress_reports
  end
end
