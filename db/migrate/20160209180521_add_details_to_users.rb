class AddDetailsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :quiz_alert,  	:boolean, :default => false
    add_index  :users, :quiz_alert
    add_column :users, :device_token,   :string
    add_column :users, :device_type,	:string
  end
end
