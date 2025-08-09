# This migration comes from forem (originally 20120228202859)
class AddNotifiedToForemPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :forem_posts, :notified, :boolean, :default => false
  end
end
