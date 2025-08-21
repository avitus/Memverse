# Custom array class for maintaining Kaminari pagination with sorted topics
class SortedTopicArray < Array
  attr_accessor :current_page, :total_pages, :limit_value, :total_count
  
  def current_page
    @current_page || 1
  end
  
  def total_pages
    @total_pages || 1
  end
  
  def limit_value
    @limit_value || Thredded.topics_per_page
  end
  
  def total_count
    @total_count || size
  end
  
  def last_page?
    current_page >= total_pages
  end
  
  def first_page?
    current_page == 1
  end
end

# Add voting sort functionality to Thredded topics controller
Rails.application.config.to_prepare do
  if defined?(Thredded::TopicsController)
    Thredded::TopicsController.class_eval do
      # Store original index method
      alias_method :original_index, :index unless method_defined?(:original_index)
      
      def index
        if params[:messageboard_id] == 'feedback' && (params[:sort] == 'votes' || params[:sort].blank?)
          # Call original method first to set up authorization and base variables
          original_index
          
          # Now override @topics with vote-sorted version
          if @topics.present?
            # Get all topic IDs and their vote scores
            topics_array = @topics.to_a
            topics_with_scores = topics_array.map { |topic_view|
              topic = topic_view.is_a?(Thredded::TopicView) ? topic_view.instance_variable_get(:@topic) : topic_view
              score = topic.vote_score
              [topic_view, score, topic.updated_at]
            }
            
            if params[:sort] == 'votes'
              # Explicit vote sorting - by engagement first (topics with votes, regardless of direction), then by score
              sorted_topics = topics_with_scores.sort_by { |_, score, _| [score == 0 ? 1 : 0, -score] }.map(&:first)
            else
              # Default feedback board sorting - positive votes first, zero votes by recency, then negative votes
              sorted_topics = topics_with_scores.sort_by { |_, score, updated_at| 
                if score > 0
                  [0, -score]  # Positive scores: group 0, sorted by score desc
                elsif score == 0
                  [1, -updated_at.to_i]  # Zero scores: group 1, sorted by recency desc  
                else
                  [2, -score]  # Negative scores: group 2, sorted by score desc (less negative first)
                end
              }.map(&:first)
            end
            
            # Replace @topics while maintaining pagination metadata
            sorted_array = SortedTopicArray.new(sorted_topics)
            sorted_array.current_page = @topics.current_page if @topics.respond_to?(:current_page)
            sorted_array.total_pages = @topics.total_pages if @topics.respond_to?(:total_pages)
            sorted_array.limit_value = @topics.limit_value if @topics.respond_to?(:limit_value)
            sorted_array.total_count = @topics.total_count if @topics.respond_to?(:total_count)
            
            @topics = sorted_array
          end
        else
          # Call original index for non-vote sorting
          original_index
        end
      end
    end
  end
end