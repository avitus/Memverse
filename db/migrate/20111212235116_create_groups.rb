class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string    :name, :null => false
      t.text      :description
      t.integer   :rank
      t.integer   :users_count, :default => 0    
      t.timestamps
    end
  end
  
  add_column :users,  :group_id, :integer  
  add_column :tweets, :group_id, :integer
  
end
