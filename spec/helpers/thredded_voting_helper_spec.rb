require 'rails_helper'

RSpec.describe ThreddedVotingHelper, type: :helper do
  let(:user) { FactoryBot.create(:user) }
  let(:messageboard) { Thredded::Messageboard.create!(name: "Test", slug: "test") }
  let(:topic) { create_topic_with_post(messageboard: messageboard, user: user) }
  let(:topic_view) { Thredded::TopicView.from_user(topic, user) }
  
  def create_topic_with_post(messageboard:, user:)
    topic = nil
    Thredded::Topic.transaction do
      topic = Thredded::Topic.create!(
        messageboard: messageboard,
        user: user,
        title: "Test Topic",
        sticky: false,
        locked: false
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: user,
        content: "Test content",
        messageboard: messageboard
      )
    end
    topic.reload
  end
  
  describe "#thredded_topic_voting" do
    before do
      allow(helper).to receive(:render).and_return("<voting-ui>")
    end
    
    it "renders voting partial for Topic object" do
      expect(helper).to receive(:render).with(
        partial: 'shared/thredded_voting',
        locals: { topic: topic }
      )
      
      helper.thredded_topic_voting(topic)
    end
    
    it "extracts topic from TopicView object" do
      expect(helper).to receive(:render).with(
        partial: 'shared/thredded_voting',
        locals: { topic: topic }
      )
      
      helper.thredded_topic_voting(topic_view)
    end
  end
  
  describe "#feedback_category_label" do
    let(:category) { double(name: "Bug Report") }
    
    before do
      allow(topic).to receive(:categories).and_return([category])
    end
    
    it "returns nil when topic has no categories" do
      allow(topic).to receive(:categories).and_return([])
      expect(helper.feedback_category_label(topic)).to be_nil
    end
    
    it "returns danger label for bug categories" do
      allow(category).to receive(:name).and_return("Bug")
      result = helper.feedback_category_label(topic)
      
      expect(result).to include("label-danger")
      expect(result).to include("Bug")
    end
    
    it "returns primary label for feature categories" do
      allow(category).to receive(:name).and_return("Feature Request")
      result = helper.feedback_category_label(topic)
      
      expect(result).to include("label-primary")
      expect(result).to include("Feature request")
    end
    
    it "returns info label for improvement categories" do
      allow(category).to receive(:name).and_return("Improvement")
      result = helper.feedback_category_label(topic)
      
      expect(result).to include("label-info")
      expect(result).to include("Improvement")
    end
    
    it "returns default label for other categories" do
      allow(category).to receive(:name).and_return("Other")
      result = helper.feedback_category_label(topic)
      
      expect(result).to include("label-default")
      expect(result).to include("Other")
    end
    
    it "capitalizes category names" do
      allow(category).to receive(:name).and_return("feature")
      result = helper.feedback_category_label(topic)
      
      expect(result).to include("Feature")
    end
  end
  
  describe "#topic_vote_count_badge" do
    context "with Topic object" do
      it "returns nil when vote score is zero" do
        allow(topic).to receive(:vote_score).and_return(0)
        expect(helper.topic_vote_count_badge(topic)).to be_nil
      end
      
      it "returns success badge for positive votes" do
        allow(topic).to receive(:vote_score).and_return(5)
        result = helper.topic_vote_count_badge(topic)
        
        expect(result).to include("badge-success")
        expect(result).to include("+5 votes")
      end
      
      it "returns danger badge for negative votes" do
        allow(topic).to receive(:vote_score).and_return(-3)
        result = helper.topic_vote_count_badge(topic)
        
        expect(result).to include("badge-danger")
        expect(result).to include("-3 votes")
      end
    end
    
    context "with TopicView object" do
      it "extracts topic and returns badge" do
        allow(topic).to receive(:vote_score).and_return(10)
        result = helper.topic_vote_count_badge(topic_view)
        
        expect(result).to include("badge-success")
        expect(result).to include("+10 votes")
      end
    end
  end
  
  describe "HTML safety" do
    it "returns HTML safe strings for category labels" do
      category = double(name: "<script>alert('xss')</script>")
      allow(topic).to receive(:categories).and_return([category])
      
      result = helper.feedback_category_label(topic)
      expect(result).to be_html_safe
      expect(result).not_to include("<script>")
    end
    
    it "returns HTML safe strings for vote badges" do
      allow(topic).to receive(:vote_score).and_return(1)
      result = helper.topic_vote_count_badge(topic)
      
      expect(result).to be_html_safe
    end
  end
end