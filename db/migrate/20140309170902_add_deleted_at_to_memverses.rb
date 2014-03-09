class AddDeletedAtToMemverses < ActiveRecord::Migration
  def change
    add_column :memverses, :deleted_at, :datetime
    add_index :memverses, :deleted_at
  end
end
