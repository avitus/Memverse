class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.string  :name
      t.text    :description
      t.string  :color

      t.timestamps
    end
    
    add_column :quests, :badge_id, :integer

    create_table :badges_users, id: false do |t|
      t.belongs_to :badge
      t.belongs_to :user
    end
     
  end
end
