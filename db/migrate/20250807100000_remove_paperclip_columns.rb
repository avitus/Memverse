class RemovePaperclipColumns < ActiveRecord::Migration[7.0]
  def up
    # Remove Paperclip columns from sermons table
    remove_column :sermons, :mp3_file_name, :string
    remove_column :sermons, :mp3_content_type, :string
    remove_column :sermons, :mp3_file_size, :integer
    remove_column :sermons, :mp3_updated_at, :datetime

    # Remove Paperclip columns from ckeditor_assets table (used by CKEditor::Picture and CKEditor::AttachmentFile)
    remove_column :ckeditor_assets, :data_file_name, :string
    remove_column :ckeditor_assets, :data_content_type, :string
    remove_column :ckeditor_assets, :data_file_size, :integer
    remove_column :ckeditor_assets, :data_updated_at, :datetime if column_exists?(:ckeditor_assets, :data_updated_at)

    # Remove Paperclip columns from blog_assets table if it exists
    if table_exists?(:blog_assets)
      remove_column :blog_assets, :blog_attachment_file_name, :string if column_exists?(:blog_assets, :blog_attachment_file_name)
      remove_column :blog_assets, :blog_attachment_content_type, :string if column_exists?(:blog_assets, :blog_attachment_content_type)
      remove_column :blog_assets, :blog_attachment_file_size, :integer if column_exists?(:blog_assets, :blog_attachment_file_size)
      remove_column :blog_assets, :blog_attachment_updated_at, :datetime if column_exists?(:blog_assets, :blog_attachment_updated_at)
    end
  end

  def down
    # Restore Paperclip columns to sermons table
    add_column :sermons, :mp3_file_name, :string
    add_column :sermons, :mp3_content_type, :string
    add_column :sermons, :mp3_file_size, :integer
    add_column :sermons, :mp3_updated_at, :datetime

    # Restore Paperclip columns to ckeditor_assets table
    add_column :ckeditor_assets, :data_file_name, :string, null: false
    add_column :ckeditor_assets, :data_content_type, :string
    add_column :ckeditor_assets, :data_file_size, :integer
    add_column :ckeditor_assets, :data_updated_at, :datetime

    # Restore Paperclip columns to blog_assets table if it exists
    if table_exists?(:blog_assets)
      add_column :blog_assets, :blog_attachment_file_name, :string
      add_column :blog_assets, :blog_attachment_content_type, :string
      add_column :blog_assets, :blog_attachment_file_size, :integer
      add_column :blog_assets, :blog_attachment_updated_at, :datetime
    end
  end
end