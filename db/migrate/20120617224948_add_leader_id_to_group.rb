class AddLeaderIdToGroup < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :leader_id, :integer
  end
end
