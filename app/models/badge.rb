# +----+---------------------+----------------------------------------------------------+-------+-------------------------+-------------------------+
# | id | name                | description                                              | color | created_at              | updated_at              |
# +----+---------------------+----------------------------------------------------------+-------+-------------------------+-------------------------+
# | 1  | Sermon on the Mount | Memorize Jesus' entire Sermon on the Mount (Matthew 5-7) | solo  | 2012-03-21 23:57:27 UTC | 2012-03-21 23:57:27 UTC |
# +----+---------------------+----------------------------------------------------------+-------+-------------------------+-------------------------+

class Badge < ActiveRecord::Base
  
  include Comparable
  
  has_and_belongs_to_many :users
  has_many :quests
    
  def <=> (other)
    MEDALS[self.color.to_sym] <=> MEDALS[other.color.to_sym]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Convert to JSON format
  # ---------------------------------------------------------------------------------------------------------- 
  def as_json(options={})
    { 
      :id          => self.id, 
      :name        => self.name,
      :description => self.description,
      :color       => self.color,
    }
  end  
  
end
