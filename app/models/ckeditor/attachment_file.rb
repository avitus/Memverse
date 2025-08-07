class Ckeditor::AttachmentFile < Ckeditor::Asset
  # Paperclip attachment (to be removed after migration)
  has_attached_file :data,
                    :url => "/ckeditor_assets/attachments/:id/:filename",
                    :path => ":rails_root/public/ckeditor_assets/attachments/:id/:filename"
  
  validates_attachment_size :data, :less_than => 100.megabytes
  validates_attachment_presence :data
  
  # Active Storage attachment
  has_one_attached :data_attachment
  
  # Active Storage validations
  validate :data_attachment_size_validation, if: -> { data_attachment.attached? }
  validate :data_attachment_presence_validation, unless: -> { data_file_name.present? }
  
  def url_thumb
    @url_thumb ||= Ckeditor::Utils.filethumb(filename)
  end
  
  def filename
    if data_attachment.attached?
      data_attachment.filename.to_s
    else
      data_file_name
    end
  end
  
  # Override url method for compatibility
  def url(style = nil)
    if data_attachment.attached?
      Rails.application.routes.url_helpers.rails_blob_url(data_attachment, only_path: true)
    else
      super
    end
  end
  
  private
  
  def data_attachment_size_validation
    if data_attachment.blob.byte_size > 100.megabytes
      errors.add(:data_attachment, 'must be less than 100MB')
    end
  end
  
  def data_attachment_presence_validation
    errors.add(:data_attachment, "can't be blank") unless data_attachment.attached?
  end
end