class DeviseUpgrade < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :reset_password_sent_at, :datetime
  end
end
