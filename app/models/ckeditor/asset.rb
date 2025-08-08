class Ckeditor::Asset < ApplicationRecord
  include Ckeditor::Orm::ActiveRecord::AssetBase
  
  # Using Active Storage instead of Paperclip backend
  def url_thumb
    @url_thumb ||= if respond_to?(:data_attachment) && data_attachment.attached?
      url_content
    else
      nil
    end
  end
  
  def filename
    if respond_to?(:data_attachment) && data_attachment.attached?
      data_attachment.filename.to_s
    else
      nil
    end
  end
  
  def size
    if respond_to?(:data_attachment) && data_attachment.attached?
      data_attachment.blob.byte_size
    else
      0
    end
  end
  
  def content_type
    if respond_to?(:data_attachment) && data_attachment.attached?
      data_attachment.content_type
    else
      nil
    end
  end
end
