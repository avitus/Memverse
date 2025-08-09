# This migration comes from forem (originally 20110626150056)
class AddUpdatedAtAndCountToForemViews < ActiveRecord::Migration[7.0]
  def change
    add_column :forem_views, :updated_at, :datetime
    add_column :forem_views, :count, :integer, :default => 0
  end
end
