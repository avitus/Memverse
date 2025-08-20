module ThreddedVotingHelper
  def thredded_topic_voting(topic)
    # Handle both TopicView and Topic objects
    actual_topic = topic.is_a?(Thredded::Topic) ? topic : topic.instance_variable_get(:@topic)
    render partial: 'shared/thredded_voting', locals: { topic: actual_topic }
  end
  
  def feedback_category_label(topic)
    return unless topic.categories.any?
    
    category_name = topic.categories.first.name.downcase
    
    label_class = case category_name
    when 'bug', 'bugs'
      'label-danger'
    when 'feature', 'features', 'feature request'
      'label-primary'
    when 'improvement', 'improvements'
      'label-info'
    else
      'label-default'
    end
    
    content_tag :span, category_name.capitalize, class: "label #{label_class}", style: "margin-right: 10px;"
  end
  
  def topic_vote_count_badge(topic_or_view)
    # Handle both TopicView and Topic objects
    topic = topic_or_view.is_a?(Thredded::Topic) ? topic_or_view : topic_or_view.instance_variable_get(:@topic)
    score = topic.vote_score
    return if score == 0
    
    badge_class = score > 0 ? 'badge-success' : 'badge-danger'
    content_tag :span, "#{score > 0 ? '+' : ''}#{score} votes", class: "badge #{badge_class}"
  end
end