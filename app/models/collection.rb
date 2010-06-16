class Collection < ActiveRecord::Base

#    -- Collection --
#    t.string   "name"
#    t.integer  "user_id",     :null => false
#    t.string   "translation", :null => false
#    t.datetime "created_at"
#    t.datetime "updated_at"
#
#    -- Collection Verse Join --
#    t.integer  "collection_id"
#    t.integer  "verse_id"
#    t.datetime "created_at"
#    t.datetime "updated_at"  
  
  has_and_belongs_to_many :verses
  
end
