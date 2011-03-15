class AddDailyStatsTable < ActiveRecord::Migration
  def self.up
    # Create Progress Table
    
    # What do we want to save?
    # - Date [entry_date]
    # - Total number of users [users]
    #     - Active Users (last 30 days) [users_active_in_month]

    # - Total number of verses [verses]

    # - Total number of memory verses [memverses]
    #     - Memorized [memverses_learning]
    #     - Learning  [memverses_memorized]
    #     - Memorized and not overdue [memverses_memorized_not_overdue]
    #     - Learning and active in month [memverses_learning_active_in_month]
    
    create_table :daily_stats do |t|
      
      t.date      :entry_date,  :null => false
      
      t.integer   :users
      t.integer   :users_active_in_month
            
      t.integer   :verses
      
      t.integer   :memverses
      t.integer   :memverses_learning
      t.integer   :memverses_memorized
      t.integer   :memverses_learning_active_in_month
      t.integer   :memverses_memorized_not_overdue
      
      t.string    :segment, :default => "Global"
      
    end
     
  end

  def self.down
    drop_table :daily_stats
  end
end
