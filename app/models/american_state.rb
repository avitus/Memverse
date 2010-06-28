class AmericanState < ActiveRecord::Base

#    t.string  "abbrev",      :limit => 20, :default => "", :null => false
#    t.string  "name",        :limit => 50, :default => "", :null => false
#    t.integer "users_count",               :default => 0
#    t.integer "population"
 
  # Relationships
  has_many :users
  has_many :tweets  
  
  # Validations
  validates_presence_of :name, :abbrev
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns hash of top countries (sorted by number of verses memorized)
  # ---------------------------------------------------------------------------------------------------------- 
  def self.top_states(numstates = 50)

    stateboard = Hash.new(0)
    
    # TODO: Optimize this - compare to top churches method
    find(:all, :conditions => ['users_count >= 3']).each { |c|
      
      score = 0
      c.users.each { |u|
        if u.last_activity_date
          if (Date.today - u.last_activity_date).to_i < 30
            # Add score
            score += u.memorized
          end
        end
      }
      stateboard[ c ] = score
    }
    
    stateboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numstates].each_with_index { |grp, index|
      if grp[0].rank.nil? 
        Tweet.create(:news => "#{grp[0].name} has joined the state leaderboard at position ##{index+1}", :american_state_id => self.id, :importance => 3)
      elsif (index+1 < grp[0].rank) and (grp[0].rank <= 20)
         Tweet.create(:news => "#{grp[0].name} is now ##{index+1} on the state leaderboard", :american_state_id => self.id, :importance => 3)       
      end
      grp[0].rank = index+1
      grp[0].save
    } 
    
  end    
  
  
  
end