# Use this hook to configure ckeditor
begin
  if defined?(Ckeditor)

    Ckeditor.parent_controller = 'ApplicationController'

    Ckeditor.setup do |config|
      # ==> ORM configuration
      # Load and configure the ORM. Supports :active_record (default), :mongo_mapper and
      # :mongoid (bson_ext recommended) by default. Other ORMs may be
      # available as additional gems.
      require "ckeditor/orm/active_record"

      # Allowed image file types for upload.
      # Set to nil or [] (empty array) for all file types
      # config.image_file_types = ["jpg", "jpeg", "png", "gif", "tiff"]

      # Allowed attachment file types for upload.
      # Set to nil or [] (empty array) for all file types
      # config.attachment_file_types = ["doc", "docx", "xls", "odt", "ods", "pdf", "rar", "zip", "tar", "swf"]
    end
  end
rescue NameError => e
  Rails.logger.warn "CKEditor not loaded: #{e.message}"
rescue NoMethodError => e
  if e.message.include?('constantize')
    Rails.logger.warn "CKEditor constantize error: #{e.message}"
  else
    raise e
  end
rescue => e
  Rails.logger.warn "CKEditor initialization error: #{e.message}"
end
