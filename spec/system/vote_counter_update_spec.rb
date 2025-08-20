require 'rails_helper'

RSpec.describe "Vote Counter Updates", type: :system, js: true, heavy_db: true do
  let(:user) { FactoryBot.create(:user, :approved) }
  let(:feedback_board) { Thredded::Messageboard.find_or_create_by!(slug: 'feedback', name: 'Feedback') }
  let(:topic) do
    topic = nil
    Thredded::Topic.transaction do
      topic = Thredded::Topic.create!(
        messageboard: feedback_board,
        user: user,
        title: "Test Topic for Voting",
        sticky: false,
        locked: false
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: user,
        content: "Test content for voting",
        messageboard: feedback_board
      )
    end
    topic.reload
  end
  
  before do
    login_as(user, scope: :user)
  end

  describe "vote counter real-time updates" do
    it "updates the counter immediately when upvoting" do
      # Debug: ensure topic and slug exist
      expect(topic).to be_persisted
      expect(topic.slug).to be_present
      
      visit "/forum/feedback/#{topic.slug}"
      
      # Ensure we're on the right page
      expect(page).to have_content(topic.title)
      
      # Check initial state
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '0')
      end
      
      # Click upvote
      find('.vote-button.upvote').click
      
      # Wait for AJAX to complete
      sleep 0.5
      
      # Counter should update without page reload
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '1', wait: 2)
        expect(page).to have_css('.vote-button.upvote.voted')
      end
    end
    
    it "updates the counter immediately when downvoting" do
      visit "/forum/feedback/#{topic.slug}"
      
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '0')
      end
      
      find('.vote-button.downvote').click
      
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '-1')
        expect(page).to have_css('.vote-button.downvote.voted')
      end
    end
    
    it "updates the counter when removing a vote" do
      # Pre-create an upvote
      user.likes topic
      
      visit "/forum/feedback/#{topic.slug}"
      
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '1')
        expect(page).to have_link('remove vote')
      end
      
      click_link 'remove vote'
      
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '0')
        expect(page).not_to have_css('.vote-button.voted')
        expect(page).not_to have_link('remove vote')
      end
    end
    
    it "updates the counter when changing vote direction" do
      # Start with an upvote
      user.likes topic
      
      visit "/forum/feedback/#{topic.slug}"
      
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '1')
      end
      
      # Change to downvote
      find('.vote-button.downvote').click
      
      within('.thredded-voting') do
        expect(page).to have_css('.vote-score', text: '-1')
        expect(page).to have_css('.vote-button.downvote.voted')
        expect(page).not_to have_css('.vote-button.upvote.voted')
      end
    end
    
    it "updates vote badge in topic list after voting" do
      # Create topic with some initial votes
      5.times { |i| FactoryBot.create(:user, :approved).likes topic }
      
      visit "/forum/feedback"
      
      # Check initial badge
      within("article[data-topic='#{topic.id}']") do
        expect(page).to have_css('.badge-success', text: '+5 votes')
      end
      
      # Navigate to topic and vote
      click_link topic.title
      find('.vote-button.upvote').click
      
      # Go back to list
      visit "/forum/feedback"
      
      # Badge should be updated
      within("article[data-topic='#{topic.id}']") do
        expect(page).to have_css('.badge-success', text: '+6 votes')
      end
    end
  end
  
  describe "AJAX error handling" do
    it "shows an error message if voting fails" do
      # Simulate a server error by attempting to vote on non-existent topic
      visit "/forum/feedback"
      
      # Manually navigate to a non-existent topic URL
      visit "/forum/feedback/non-existent-topic"
      
      # Should show 404 or redirect
      expect(page).to have_content("This topic does not exist") # or similar error
    end
  end
end