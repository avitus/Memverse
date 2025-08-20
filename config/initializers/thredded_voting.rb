# Extend Thredded topics with voting functionality
Rails.application.config.to_prepare do
  if defined?(Thredded::Topic)
    Thredded::Topic.class_eval do
      acts_as_votable
      
      # Add vote count to topic for easy sorting
      def vote_score
        self.get_upvotes.size - self.get_downvotes.size
      end
      
      # Check if user has voted
      def voted_by?(user)
        return false unless user
        user.voted_for?(self)
      end
      
      # Get vote direction for user
      def vote_direction_by(user)
        return nil unless user
        
        if user.voted_for?(self)
          user.voted_as_when_voted_for(self) ? 'up' : 'down'
        else
          nil
        end
      end
    end
  end
end