class CreateQuests < ActiveRecord::Migration
  def self.up
    create_table :quests do |t|
      t.integer :level
      t.string  :task
      t.text    :description
      t.string  :objective
      t.string  :qualifier
      t.integer :quantity
      t.string  :url

      t.timestamps
    end
    
    add_index :quests, :level
    add_index :quests, :objective 
    add_index :quests, :qualifier
    
    create_table :quests_users, :id => false do |t|
      t.belongs_to :quest
      t.belongs_to :user
    end
        
    # Create blogger role
    blogger_role = Role.create(:name => 'blogger')
    admin_role   = Role.find_by_name('admin')
    
    # Create admin and blogger role to me
    u = User.find_by_login('avitus')
    if u 
      u.roles << admin_role
      u.roles << blogger_role
    end
    
    # Set rank default to 0
    add_column :users, :level, :integer, :null => false, :default => 0   
    
    # Add column to track referrals
    add_column :users, :referred_by, :integer
    add_index  :users, :referred_by

  end

  def self.down
    drop_table :quests
    drop_table :quests_users
    remove_column :users, :level
    remove_column :users, :referred_by
  end
end