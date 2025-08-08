class Ckeditor::Picture < Ckeditor::Asset
  # Active Storage attachment
  has_one_attached :data_attachment
  
  # Active Storage validations
  validate :data_attachment_size_validation
  validate :data_attachment_presence_validation

  def url_content
    if data_attachment.attached?
      variant = data_attachment.variant(resize_to_limit: [800, nil])
      Rails.application.routes.url_helpers.rails_representation_url(variant, only_path: true)
    end
  end
  
  def url_thumb  
    if data_attachment.attached?
      variant = data_attachment.variant(resize_to_fill: [118, 100])
      Rails.application.routes.url_helpers.rails_representation_url(variant, only_path: true)
    end
  end
  
  # Active Storage URL method
  def url(style = :original)
    return unless data_attachment.attached?
    
    case style
    when :content
      url_content
    when :thumb
      url_thumb
    else
      Rails.application.routes.url_helpers.rails_blob_url(data_attachment, only_path: true)
    end
  end
  
  private
  
  def data_attachment_size_validation
    return unless data_attachment.attached?
    
    if data_attachment.blob.byte_size > 2.megabytes
      errors.add(:data_attachment, 'must be less than 2MB')
    end
  end
  
  def data_attachment_presence_validation
    errors.add(:data_attachment, "can't be blank") unless data_attachment.attached?
  end
end