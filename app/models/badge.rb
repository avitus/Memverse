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
      id: self.id, 
      name: self.name,
      description: self.description,
      color: self.color,
    }
  end 
  
  # ----------------------------------------------------------------------------------------------------------
  # Check whether badge requirements have been achieved NOTE: does not award badge
  # ----------------------------------------------------------------------------------------------------------   
  def achieved?(user)
    # Only check if more valuable badge has not already been awarded
    user_badge_in_series = user.badges.where(name: self.name).sort.last
    
    if user_badge_in_series && user_badge_in_series >= self
      return false
    else
      self.quests.each do |q|
          if !user.quests.include?(q)
            return false
          end
      end
      return true
    end
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Adds badge to list of awards (only if not already awarded)
  # ---------------------------------------------------------------------------------------------------------- 
  def award_badge(user)
    if !user.badges.include?(self)  # can only be awarded a badge once
      # First remove all lower level badges
      user.badges.delete( Badge.where(name: self.name) )
      # Award new badge
      user.badges << self      
    end    
  end
  
end
