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
        return 'up' if user.voted_up_on?(self)
        return 'down' if user.voted_down_on?(self)
        nil
      end
    end
  end
end