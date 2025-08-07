class Sermon < ApplicationRecord
  # Paperclip attachment (to be removed after migration)
  # Temporarily disabled for testing - uncomment when fully migrating from Paperclip
  # has_attached_file :mp3
  
  # Active Storage attachment
  has_one_attached :mp3_attachment
  
  belongs_to :pastor, optional: true
  belongs_to :church, optional: true
  belongs_to :user, optional: true
  belongs_to :uberverse, optional: true
  
  # Compatibility method to use Active Storage if available, otherwise Paperclip
  def mp3_url
    if mp3_attachment.attached?
      Rails.application.routes.url_helpers.rails_blob_url(mp3_attachment, only_path: true)
    elsif mp3.present?
      mp3.url
    end
  end
  
  # Return Active Storage attachment or fallback to Paperclip data
  def mp3
    if mp3_attachment.attached?
      mp3_attachment
    else
      # For backwards compatibility, create a mock object with Paperclip data
      if mp3_file_name.present?
        OpenStruct.new(
          present?: true,
          url: "/system/sermons/mp3s/#{id}/original/#{mp3_file_name}",
          file_name: mp3_file_name,
          content_type: mp3_content_type,
          file_size: mp3_file_size
        )
      else
        nil
      end
    end
  end
end
