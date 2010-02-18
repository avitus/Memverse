class State < ActiveRecord::Base

#    t.string  "abbrev",      :limit => 20, :default => "", :null => false
#    t.string  "name",        :limit => 50, :default => "", :null => false
#    t.integer "users_count",               :default => 0
#    t.integer "population"
 
  # Relationships
  has_many :users
  
  # Validations
  validates_presence_of :name, :abbrev
  
end