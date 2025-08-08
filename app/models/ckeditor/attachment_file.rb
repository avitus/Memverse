class Ckeditor::AttachmentFile < Ckeditor::Asset
  # Active Storage attachment
  has_one_attached :data_attachment
  
  # Active Storage validations
  validate :data_attachment_size_validation
  validate :data_attachment_presence_validation
  
  def url_thumb
    @url_thumb ||= Ckeditor::Utils.filethumb(filename)
  end
  
  def filename
    data_attachment.attached? ? data_attachment.filename.to_s : nil
  end
  
  # Active Storage URL method
  def url(style = nil)
    if data_attachment.attached?
      Rails.application.routes.url_helpers.rails_blob_url(data_attachment, only_path: true)
    end
  end
  
  private
  
  def data_attachment_size_validation
    return unless data_attachment.attached?
    
    if data_attachment.blob.byte_size > 100.megabytes
      errors.add(:data_attachment, 'must be less than 100MB')
    end
  end
  
  def data_attachment_presence_validation
    errors.add(:data_attachment, "can't be blank") unless data_attachment.attached?
  end
end