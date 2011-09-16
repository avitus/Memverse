class Sermon < ActiveRecord::Base
  has_attached_file :mp3
  
  belongs_to :pastor
  belongs_to :church
  belongs_to :user
  belongs_to :uberverse
  
end
