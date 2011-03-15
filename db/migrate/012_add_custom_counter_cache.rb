class AddCustomCounterCache < ActiveRecord::Migration
  def self.up
     
    # Add counter caches for memorized/learning verses
    add_column :users, :memorized,          :integer, :default => 0
    add_column :users, :learning,           :integer, :default => 0
    add_column :users, :last_activity_date, :date

    # Initialized the caches
    User.find(:all).each { |u| 
      u.memorized           = Memverse.count(:all, :conditions => ["user_id = ? and status = ?", u.id, "Memorized"])
      u.learning            = Memverse.count(:all, :conditions => ["user_id = ? and status = ?", u.id, "Learning"])
      u.last_activity_date  = u.init_activity_date
      u.save
    }


  end

  def self.down
    remove_column :users, :memorized
    remove_column :users, :learning
    remove_column :users, :last_activity_date
  end
end
