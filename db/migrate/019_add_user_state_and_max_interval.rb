class AddUserStateAndMaxInterval < ActiveRecord::Migration
 
  def self.up
   
    # Create US States Table - created separately to include data    
    add_column :users,            :max_interval,      :integer, :default => 366
    add_column :users,            :mnemonic_use,      :string,  :default => "Learning"
    add_column :users,            :american_state_id, :integer
    add_column :american_states,  :users_count,       :integer, :default => 0  
    add_column :american_states,  :population,        :integer

    # Create counter cache for users per state
    AmericanState.reset_column_information  
    AmericanState.all.each do |c|  
      c.update_attribute :users_count, c.users.length  
    end      
    
  end


  def self.down
    drop_table    :american_states
    remove_column :users,           :max_interval
    remove_column :users,           :mnemonic_use
    remove_column :users,           :american_state_id
  end
  
end






