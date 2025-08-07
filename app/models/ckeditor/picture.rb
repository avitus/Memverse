class Ckeditor::Picture < Ckeditor::Asset
  # Paperclip attachment (to be removed after migration)
  has_attached_file :data,
                    :url  => "/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    :path => ":rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    :styles => { :content => '800>', :thumb => '118x100#' }

  validates_attachment_size :data, :less_than => 2.megabytes
  validates_attachment_presence :data

  # Active Storage attachment
  has_one_attached :data_attachment
  
  # Active Storage validations
  validate :data_attachment_size_validation, if: -> { data_attachment.attached? }
  validate :data_attachment_presence_validation, unless: -> { data_file_name.present? }

  def url_content
    if data_attachment.attached?
      variant = data_attachment.variant(resize_to_limit: [800, nil])
      Rails.application.routes.url_helpers.rails_representation_url(variant, only_path: true)
    else
      url(:content)
    end
  end
  
  def url_thumb  
    if data_attachment.attached?
      variant = data_attachment.variant(resize_to_fill: [118, 100])
      Rails.application.routes.url_helpers.rails_representation_url(variant, only_path: true)
    else
      url(:thumb)
    end
  end
  
  # Override url method for compatibility
  def url(style = :original)
    if data_attachment.attached?
      case style
      when :content
        url_content
      when :thumb
        url_thumb
      else
        Rails.application.routes.url_helpers.rails_blob_url(data_attachment, only_path: true)
      end
    else
      super
    end
  end
  
  private
  
  def data_attachment_size_validation
    if data_attachment.blob.byte_size > 2.megabytes
      errors.add(:data_attachment, 'must be less than 2MB')
    end
  end
  
  def data_attachment_presence_validation
    errors.add(:data_attachment, "can't be blank") unless data_attachment.attached?
  end
end