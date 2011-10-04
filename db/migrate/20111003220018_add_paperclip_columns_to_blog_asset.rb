class AddPaperclipColumnsToBlogAsset < ActiveRecord::Migration
  def change
    add_column :blog_assets, :blog_attachment_file_name,    :string
    add_column :blog_assets, :blog_attachment_content_type, :string
    add_column :blog_assets, :blog_attachment_file_size,    :integer
    add_column :blog_assets, :blog_attachment_updated_at,   :datetime    
  end
end