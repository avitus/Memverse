class Tweet < ActiveRecord::Base

#    t.integer  "importance", :default => 5
#    t.integer  "user_id"
#    t.integer  "church_id"
#    t.integer  "state_id"
#    t.integer  "country_id"
#    t.string   "news"
#    t.datetime "created_at"
#    t.datetime "updated_at"

  # Relationships
  belongs_to  :user
  belongs_to  :church
  belongs_to  :group
  belongs_to  :country
  belongs_to  :smerican_state
  
  # Validations
  validates_presence_of   :news
  
end
