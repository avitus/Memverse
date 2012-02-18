class RemoveUnusedColumnsFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :state
    remove_column :users, :blog_attachment_file_name    # Seems as though the 4 blog_attachment columns didn't exist on production DB
    remove_column :users, :blog_attachment_content_type # Had to comment out these 4 lines for migration to run
    remove_column :users, :blog_attachment_file_size
    remove_column :users, :blog_attachment_updated_at
    remove_column :users, :bb_2011_age_group
    remove_column :users, :bb_2011_track
    remove_column :users, :show_toolbar
  end

  def down
    add_column :users, :show_toolbar, :boolean
    add_column :users, :bb_2011_track, :string
    add_column :users, :bb_2011_age_group, :string
    add_column :users, :blog_attachment_updated_at, :string
    add_column :users, :blog_attachment_file_size, :string
    add_column :users, :blog_attachment_content_type, :string
    add_column :users, :blog_attachment_file_name, :string
    add_column :users, :state, :string
  end
end
