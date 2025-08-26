class QuizErrorLog < ApplicationRecord
  belongs_to :quiz, optional: true
  
  scope :recent, -> { where('created_at > ?', 24.hours.ago) }
end