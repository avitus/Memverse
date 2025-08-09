# This migration comes from forem (originally 20140917201619)
class AddPositionToForums < ActiveRecord::Migration[7.0]
  def change
    add_column :forem_forums, :position, :integer, :default => 0
  end
end
