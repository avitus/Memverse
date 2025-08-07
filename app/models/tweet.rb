class Tweet < ApplicationRecord

#    t.integer  "importance", :default => 5
#    t.integer  "user_id"
#    t.integer  "church_id"
#    t.integer  "state_id"
#    t.integer  "country_id"
#    t.string   "news"
#    t.datetime "created_at"
#    t.datetime "updated_at"

  # Relationships
  belongs_to  :user, optional: true
  belongs_to  :church, optional: true
  belongs_to  :group, optional: true
  belongs_to  :country, optional: true
  belongs_to  :american_state, optional: true
  
  # Validations
  validates_presence_of   :news
  
end
