class CreateNewsEvents < ActiveRecord::Migration
  def self.up
  
    # Create Events Table
    create_table  :tweets do |t|
      t.integer   :importance,  :default => 5
      t.integer   :user_id
      t.integer   :church_id
      t.integer   :american_state_id
      t.integer   :country_id
      t.string    :news
      t.timestamps
    end
    
    add_index :tweets, :importance
    add_index :tweets, :user_id
    add_index :tweets, :church_id
    add_index :tweets, :american_state_id
    add_index :tweets, :country_id    
      
  end

  def self.down
    drop_table :tweets  
  end
end
