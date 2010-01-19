class CreateChurches < ActiveRecord::Migration
  def self.up
  
    # Create Churches Table
    create_table  :churches do |t|
      t.string    :name,          :null => false
      t.text      :description
      t.integer   :country_id
      t.timestamps
    end
    
    # Add columns for country and church for user
    add_column :users, :church_id,        :integer
    add_column :users, :country_id,       :integer
    add_column :users, :language,         :string,  :default => "English"
    add_column :users, :time_allocation,  :integer, :default => 5
      
    # Country table will be downloaded and added manually
      
  end

  def self.down
    drop_table :churches
    remove_column :users, :church_id
    remove_column :users, :country_id
    remove_column :users, :language
    remove_column :users, :time_allocation
  end
end
