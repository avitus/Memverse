class Sermon < ApplicationRecord
  # Active Storage attachment
  has_one_attached :mp3_attachment
  
  belongs_to :pastor, optional: true
  belongs_to :church, optional: true
  belongs_to :user, optional: true
  belongs_to :uberverse, optional: true
  
  # Active Storage URL method
  def mp3_url
    if mp3_attachment.attached?
      Rails.application.routes.url_helpers.rails_blob_url(mp3_attachment, only_path: true)
    end
  end
  
  # Return Active Storage attachment
  def mp3
    mp3_attachment if mp3_attachment.attached?
  end
end
