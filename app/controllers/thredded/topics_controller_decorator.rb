# Decorator to add vote sorting to feedback messageboard
module Thredded
  module TopicsControllerDecorator
    extend ActiveSupport::Concern

    included do
      before_action :apply_vote_sorting, only: [:index]
    end

    private

    def apply_vote_sorting
      # Only apply vote sorting to feedback messageboard
      return unless @messageboard&.slug == 'feedback'
      
      # Check if user requested vote sorting
      if params[:sort] == 'votes'
        @topics = @topics.left_joins(:votes_for)
          .group('thredded_topics.id')
          .order('COUNT(votes.id) DESC, thredded_topics.updated_at DESC')
      end
    end
  end
end

# Apply the decorator
Rails.application.config.to_prepare do
  Thredded::TopicsController.include(Thredded::TopicsControllerDecorator)
end