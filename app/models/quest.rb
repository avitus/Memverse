class Quest < ActiveRecord::Base
  has_and_belongs_to_many :users
   
  # ----------------------------------------------------------------------------------------------------------
  # Returns true if a task has been completed
  # ----------------------------------------------------------------------------------------------------------       
  def complete?(user)
    case self.objective
      
      when 'Verses'
        
        case self.qualifier
          when 'Learning'
            user.learning >= self.quantity
          when 'Memorized'
            user.memorized >= self.quantity
          else
            false
        end
      
      when 'Gospels'
        case self.qualifier
          when 'Learning'
            user.memverses.gospel.learning.length >= self.quantity
          when 'Memorized'
            user.memverses.gospel.memorized.length >= self.quantity
          else
            false
        end        

      
      when 'Epistles'
        case self.qualifier
          when 'Learning'
            user.memverses.epistle.learning.length >= self.quantity
          when 'Memorized'
            user.memverses.epistle.memorized.length >= self.quantity
          else
            false
        end        
      
      when 'Wisdom'
        case self.qualifier
          when 'Learning'
            user.memverses.wisdom.learning.length >= self.quantity
          when 'Memorized'
            user.memverses.wisdom.memorized.length >= self.quantity
          else
            false
        end        
                              
      when 'History'
        case self.qualifier
          when 'Learning'
            user.memverses.history.learning.length >= self.quantity
          when 'Memorized'
            user.memverses.history.memorized.length >= self.quantity
          else
            false
        end        
      
      when 'Prophecy'
        case self.qualifier
          when 'Learning'
            user.memverses.prophecy.learning.length >= self.quantity
          when 'Memorized'
            user.memverses.prophecy.memorized.length >= self.quantity
          else
            false
        end        
                       
      when 'Chapters'
        case self.qualifier
          when 'Learning'
            user.complete_chapters.length >= self.quantity 
          when 'Memorized'
            user.complete_chapters.select { |ch| ch[0] == "Memorized" }
          else
            false
        end
        
      when 'Books'
        false
        
      when 'Accuracy'
        user.accuracy >= self.quantity
        
      when 'References'
        user.ref_grade >= self.quantity
        
      when 'Sessions'
        user.num_sessions >= self.quantity
        
      when 'Referrals'
        user.num_referrals >= self.quantity
      
      when 'Url'
        false # Quest if flagged as complete when user visits URL
        
      else
        false
        
    end
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Adds task to list of completed tasks
  # ----------------------------------------------------------------------------------------------------------    
  def check_quest_off(user)
    user.quests << self
  end
    
end
