class AddDeletedAtToPassages < ActiveRecord::Migration
  def change
    add_column :passages, :deleted_at, :datetime
    add_index :passages, :deleted_at
  end
end
