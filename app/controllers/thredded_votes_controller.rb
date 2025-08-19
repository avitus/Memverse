class ThreddedVotesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_topic

  def upvote
    @topic.upvote_by current_user
    respond_to do |format|
      format.html { redirect_back(fallback_location: thredded.topic_path(@topic)) }
      format.json { render json: { score: @topic.vote_score, voted: 'up' } }
    end
  end

  def downvote
    @topic.downvote_by current_user
    respond_to do |format|
      format.html { redirect_back(fallback_location: thredded.topic_path(@topic)) }
      format.json { render json: { score: @topic.vote_score, voted: 'down' } }
    end
  end

  def unvote
    @topic.unvote_by current_user
    respond_to do |format|
      format.html { redirect_back(fallback_location: thredded.topic_path(@topic)) }
      format.json { render json: { score: @topic.vote_score, voted: nil } }
    end
  end

  private

  def find_topic
    @topic = Thredded::Topic.find(params[:id])
    authorize_voting!
  end

  def authorize_voting!
    # Check if user can view this topic
    unless Thredded::TopicPolicy.new(current_user, @topic).read?
      redirect_to thredded.root_path, alert: 'You are not authorized to vote on this topic.'
    end
  end
end