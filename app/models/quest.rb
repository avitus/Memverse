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
        
      when 'Sessions'
        user.num_sessions >= self.quantity
      
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
