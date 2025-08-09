class RemoveChurchStringFromUsers < ActiveRecord::Migration[7.0]
  def up
    remove_column :users, :church
  end

  def down
    add_column :users, :church, :string
  end
end
