class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.string  :name
      t.text    :description
      t.string  :color

      t.timestamps
    end
    
    add_column :quests, :badge_id, :integer
        
  end
end
