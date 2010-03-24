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
  def self.top_countries(numcountries=10)

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
    
    return countryboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numcountries]
    
  end    
  
end