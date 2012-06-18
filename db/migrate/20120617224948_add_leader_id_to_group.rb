class AddLeaderIdToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :leader_id, :integer
  end
end
