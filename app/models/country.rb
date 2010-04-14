class Country < ActiveRecord::Base

  #  t.string    :name            VARCHAR(80) :null => false
  #  t.string    :printable_name  VARCHAR(80) :null => false
  #  t.string    :iso3            CHAR(3) 
  #  t.string    :numcode         SMALLINT
  
  # Relationships
  has_many :users
  has_many :churches
  has_many :tweets  
  
  
  # Validations
  validates_presence_of :name, :printable_name  
  
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns hash of top countries (sorted by number of verses memorized)
  # ---------------------------------------------------------------------------------------------------------- 
  def self.top_countries(numcountries=20)

    countryboard = Hash.new(0)
    
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
      countryboard[ c ] = score
    }
    
    countryboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numcountries].each_with_index { |grp, index|
      if grp[0].rank.nil? 
        Tweet.create(:news => "#{grp[0].printable_name} has joined the country leaderboard at position ##{index+1}", :country_id => self.id, :importance => 3)
      elsif (index+1 < grp[0].rank)
         Tweet.create(:news => "#{grp[0].printable_name} is now ##{index+1} on the country leaderboard", :country_id => self.id, :importance => 3)       
      end
      logger.info("** Saving countryboard info for: #{grp[0].printable_name}")
      grp[0].rank = index+1
      grp[0].save
    } 
    
  end    
  
end