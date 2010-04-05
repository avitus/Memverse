class Church < ActiveRecord::Base
  
  #  t.string    :name,          :null => false
  #  t.text      :description
  #  t.text      :url   --- not yet implemented
  #  t.integer   :country_id
  #  t.timestamps

  # Relationships
  has_many    :users
  has_many    :tweets
  belongs_to  :country
  
  # Validations
  validates_presence_of   :name 
  validates_uniqueness_of :name  
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns *array* of top churches (sorted by number of verses memorized)
  # ---------------------------------------------------------------------------------------------------------- 
  def self.top_churches(numchurches=50)

    churchboard = Hash.new(0)
    
    # TODO: Optimize this
    find(:all, :conditions => ['users_count >= 3']).each { |grp|
      
      score = 0
      grp.users.each { |u|
        if u.last_activity_date
          if (Date.today - u.last_activity_date).to_i < 30
            # Add score
            score += u.memorized
          end
        end
      }
      churchboard[ grp ] = score
    }
    
    churchboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numchurches].each_with_index { |grp, index|
      if grp[0].rank.nil? or index+1 < grp[0].rank
        Tweet.create(:news => "#{grp[0].name} is now ##{index+1} on the church leaderboard", :church_id => self.id, :importance => 3)
      end
      grp[0].rank = index+1
      grp[0].save
    }       
    
  end   
  
  
end