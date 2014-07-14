class RemoveChurchStringFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :church
  end

  def down
    add_column :users, :church, :string
  end
end
