class CreateQuests < ActiveRecord::Migration
  def self.up
    create_table :quests do |t|
      t.integer :rank
      t.string :task
      t.text :description

      t.timestamps
    end
    
    add_index :quests, :rank   
    
    create_table :quests_users, :id => false do |t|
      t.belongs_to :quest
      t.belongs_to :user
    end
        

    # Create blogger role
    blogger_role = Role.create(:name => 'blogger')
    admin_role   = Role.find_by_name('admin')
    
    # Create admin and blogger role to me
    u = User.find_by_login('avitus') 
    u.roles << admin_role
    u.roles << blogger_role
  end

  def self.down
    drop_table :quests
    drop_table :quests_users
  end
end