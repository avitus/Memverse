class AddForemAutoSubscribeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :forem_auto_subscribe, :boolean, :default => false
  end  
end
