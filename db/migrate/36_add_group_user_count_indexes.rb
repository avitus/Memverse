class AddGroupUserCountIndexes < ActiveRecord::Migration
 
  def self.up
    add_index  :churches, 			:name, 				:unique => true
    add_index  :churches, 			:users_count

    add_index  :american_states,	:name, 				:unique => true
    add_index  :american_states,	:users_count
    
    add_index  :countries, 			:printable_name,	:unique => true
    add_index  :countries, 			:users_count    


  end

  def self.down
    remove_index :churches,			:name
    remove_index :churches,			:users_count
    remove_index :american_states,	:name
    remove_index :american_states,	:users_count
    remove_index :countries,		:printable_name
    remove_index :countries,		:users_count
  end
  
end
