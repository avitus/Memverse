require 'rails_helper'

RSpec.describe "Thredded Voting System", type: :system, js: true, heavy_db: true do
  let(:user) { FactoryBot.create(:user, :approved) }
  let(:another_user) { FactoryBot.create(:user, :approved) }
  let(:feedback_board) { 
    FactoryBot.create(:messageboard, name: "Feedback & Feature Requests", slug: "feedback", description: "Vote on features")
  }
  
  before do
    feedback_board # Ensure it exists
  end
  
  describe "voting on topic detail page" do
    let!(:topic) { FactoryBot.create(:topic, messageboard: feedback_board, user: user, title: "Add dark mode", with_posts: 1) }
    
    context "as anonymous user" do
      it "shows login prompt instead of voting buttons" do
        visit "/forum/feedback/#{topic.slug}"
        
        expect(page).to have_content("Add dark mode")
        expect(page).to have_content("Login to vote")
        expect(page).not_to have_css(".vote-button")
      end
      
      it "redirects to login when clicking login to vote" do
        visit "/forum/feedback/#{topic.slug}"
        click_link "Login to vote"
        
        expect(page).to have_current_path(new_user_session_path)
      end
    end
    
    context "as authenticated user" do
      before { login_as(user) }
      
      it "shows voting interface with zero score initially" do
        visit "/forum/feedback/#{topic.slug}"
        
        expect(page).to have_css(".thredded-voting")
        expect(page).to have_css(".vote-button.upvote")
        expect(page).to have_css(".vote-button.downvote")
        expect(page).to have_css(".vote-score", text: "0")
        expect(page).not_to have_content("remove vote")
      end
      
      it "allows upvoting and updates score without page reload" do
        visit "/forum/feedback/#{topic.slug}"
        
        find(".vote-button.upvote").click
        
        expect(page).to have_css(".vote-score", text: "1")
        expect(page).to have_css(".vote-button.upvote.voted")
        expect(page).to have_content("remove vote")
        
        # Verify persistence
        refresh
        expect(page).to have_css(".vote-score", text: "1")
        expect(page).to have_css(".vote-button.upvote.voted")
      end
      
      it "allows downvoting and updates score" do
        visit "/forum/feedback/#{topic.slug}"
        
        find(".vote-button.downvote").click
        
        expect(page).to have_css(".vote-score", text: "-1")
        expect(page).to have_css(".vote-button.downvote.voted")
        expect(page).to have_content("remove vote")
      end
      
      it "allows changing vote from up to down" do
        visit "/forum/feedback/#{topic.slug}"
        
        # First upvote
        find(".vote-button.upvote").click
        expect(page).to have_css(".vote-score", text: "1")
        
        # Then downvote
        find(".vote-button.downvote").click
        expect(page).to have_css(".vote-score", text: "-1")
        expect(page).to have_css(".vote-button.downvote.voted")
        expect(page).not_to have_css(".vote-button.upvote.voted")
      end
      
      it "allows removing vote" do
        visit "/forum/feedback/#{topic.slug}"
        
        # Vote first
        find(".vote-button.upvote").click
        expect(page).to have_css(".vote-score", text: "1")
        
        # Remove vote
        click_link "remove vote"
        expect(page).to have_css(".vote-score", text: "0")
        expect(page).not_to have_css(".vote-button.voted")
        expect(page).not_to have_content("remove vote")
      end
    end
    
    context "with multiple users voting", js: true do
      before do
        # First user votes
        login_as(user)
        visit "/forum/feedback/#{topic.slug}"
        find(".vote-button.upvote").click
        
        # Wait for AJAX to complete
        expect(page).to have_css(".vote-score", text: "1")
        
        # Logout and switch to another user
        logout
        login_as(another_user)
      end
      
      it "shows cumulative score from all users" do
        visit "/forum/feedback/#{topic.slug}"
        
        # Should see the vote from the first user
        expect(page).to have_css(".vote-score", text: "1")
        
        # Another user upvotes
        find(".vote-button.upvote").click
        
        # Wait for AJAX and check updated score
        expect(page).to have_css(".vote-score", text: "2", wait: 2)
      end
    end
  end
  
  describe "vote display in topic list" do
    let!(:upvoted_topic) { FactoryBot.create(:topic, messageboard: feedback_board, user: user, title: "Popular feature request", with_posts: 1) }
    let!(:downvoted_topic) { FactoryBot.create(:topic, messageboard: feedback_board, user: user, title: "Unpopular suggestion", with_posts: 1) }
    let!(:neutral_topic) { FactoryBot.create(:topic, messageboard: feedback_board, user: user, title: "Neutral topic", with_posts: 1) }
    
    before do
      # Set up votes
      user.likes upvoted_topic
      another_user.likes upvoted_topic
      
      user.dislikes downvoted_topic
      another_user.dislikes downvoted_topic
    end
    
    it "shows vote badges in topic list" do
      visit "/forum/feedback"
      
      within("article[data-topic='#{upvoted_topic.id}']") do
        expect(page).to have_css(".badge-success", text: "+2 votes")
      end
      
      within("article[data-topic='#{downvoted_topic.id}']") do
        expect(page).to have_css(".badge-danger", text: "-2 votes")
      end
      
      within("article[data-topic='#{neutral_topic.id}']") do
        expect(page).not_to have_css(".badge")
      end
    end
  end
  
  describe "vote sorting" do
    let!(:topics) do
      5.times.map do |i|
        FactoryBot.create(:topic, messageboard: feedback_board, user: user, title: "Feature #{i}", with_posts: 1)
      end
    end
    
    before do
      # Create different vote patterns
      3.times { |i| FactoryBot.create(:user).likes topics[0] }  # +3 votes
      2.times { |i| FactoryBot.create(:user).likes topics[1] }  # +2 votes
      1.times { |i| FactoryBot.create(:user).dislikes topics[2] } # -1 vote
      # topics[3] has 0 votes
      # topics[4] has 0 votes
    end
    
    it "sorts topics by vote count when requested" do
      visit "/forum/feedback"
      
      # Default sort (most recent)
      topic_titles = all(".thredded--topics--title a").map(&:text)
      expect(topic_titles).to eq(topics.reverse.map(&:title))
      
      # Sort by votes
      click_link "Most Votes"
      
      topic_titles = all(".thredded--topics--title a").map(&:text)
      expect(topic_titles[0]).to eq("Feature 0") # +3 votes
      expect(topic_titles[1]).to eq("Feature 1") # +2 votes
    end
    
    it "preserves sort option in pagination" do
      visit "/forum/feedback?sort=votes"
      
      expect(page).to have_css(".btn-primary", text: "Most Votes")
      expect(page).to have_css(".btn-default", text: "Most Recent")
    end
  end
  
  describe "voting on non-feedback boards" do
    let(:regular_board) { 
      FactoryBot.create(:messageboard, name: "General Discussion", slug: "general")
    }
    
    let!(:topic) { FactoryBot.create(:topic, messageboard: regular_board, user: user, title: "Regular topic", with_posts: 1) }
    
    it "does not show voting interface on non-feedback boards" do
      login_as(user)
      visit "/forum/general/#{topic.slug}"
      
      expect(page).not_to have_css(".thredded-voting")
      expect(page).not_to have_css(".vote-button")
    end
    
    it "does not show vote badges in non-feedback board lists" do
      user.likes topic # Vote exists but shouldn't display
      
      visit "/forum/general"
      
      expect(page).not_to have_css(".badge")
      expect(page).not_to have_content("votes")
    end
  end
end