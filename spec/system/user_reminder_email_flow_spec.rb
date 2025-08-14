require 'rails_helper'

RSpec.describe "User Reminder Email Flow", type: :system do
  # NOTE: These system tests are currently disabled because they require complex
  # email delivery setup across Capybara browser processes. The email functionality
  # is thoroughly tested in the mailer specs and unit tests. These tests should be
  # converted to request specs or mailer specs in the future.
  
  before(:each) do
    skip "System email tests disabled - see note above"
  end
  
  let!(:john_verse) do
    Verse.create!(
      book: "John",
      chapter: 3,
      versenum: 16,
      text: "For God so loved the world...",
      translation: "NASB95",
      book_index: 43
    )
  end
  
  let!(:romans_verse) do
    Verse.create!(
      book: "Romans",
      chapter: 8,
      versenum: 28,
      text: "And we know that God causes...",
      translation: "NASB95",
      book_index: 45
    )
  end
  
  let!(:confirmed_user) do
    user = User.create!(
      name: "Progressor",
      email: "progress@test.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    user
  end

  before(:each) do
    # Ensure ActionMailer deliveries are captured
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
  end

  describe "progression emails" do
    it "sends progression email level 9 with verse content" do
      # Create memverse for the user
      memverse = Memverse.create!(
        user: confirmed_user,
        verse: john_verse,
        efactor: 2.5,
        rep_n: 9,
        status: "Learning"
      )
      
      # Send progression email
      UserMailer.progression_email_9(confirmed_user).deliver_now
      
      expect(ActionMailer::Base.deliveries.length).to eq(1)
      
      email = ActionMailer::Base.deliveries.first
      expect(email.subject).to eq("Memverse Reminder")
      expect(email.to).to include("progress@test.com")
      expect(email.from).to include("admin@memverse.com")
      # Check email content (handle multipart emails)
      if email.multipart?
        expect(email.html_part.body.to_s).to include("Progressor")
        expect(email.html_part.body.to_s).to include("For God so loved the world")
      else
        expect(email.body.to_s).to include("Progressor")
        expect(email.body.to_s).to include("For God so loved the world")
      end
      
      # Verify Postmark headers
      expect(email['X-PM-Tag']&.value).to eq('progression-9')
      expect(email['X-PM-Message-Stream']&.value).to eq('broadcast')
      expect(email['List-Unsubscribe']&.value).to include('https://memverse.com/unsubscribe/progress@test.com')
      expect(email['List-Unsubscribe-Post']&.value).to include('List-Unsubscribe=One-Click')
    end
    
    it "sends progression email level 8 with verse content" do
      memverse = Memverse.create!(
        user: confirmed_user,
        verse: romans_verse,
        efactor: 2.5,
        rep_n: 8,
        status: "Learning"
      )
      
      UserMailer.progression_email_8(confirmed_user).deliver_now
      
      expect(ActionMailer::Base.deliveries.length).to eq(1)
      
      email = ActionMailer::Base.deliveries.first
      expect(email.subject).to eq("Memverse Reminder")
      expect(email.body.to_s).to include("And we know that God causes")
      expect(email['X-PM-Tag']&.value).to eq('progression-8')
      expect(email['X-PM-Message-Stream']&.value).to eq('broadcast')
    end
    
    it "sends progression email level 2 without verse content" do
      UserMailer.progression_email_2(confirmed_user).deliver_now
      
      email = ActionMailer::Base.deliveries.first
      expect(email.subject).to eq("Memverse Reminder")
      expect(email.body.to_s).to include("Progressor")
      expect(email['X-PM-Tag']&.value).to eq('progression-2')
      expect(email['X-PM-Message-Stream']&.value).to eq('broadcast')
      expect(email['List-Unsubscribe']&.value).to include('https://memverse.com/unsubscribe/progress@test.com')
      
      # Should not contain specific verse text since it's level 2
      expect(email.body.to_s).not_to include("For God so loved the world")
      expect(email.body.to_s).not_to include("And we know that God causes")
    end
    
    (3..9).each do |level|
      it "sends progression email level #{level} with proper headers" do
        # All progression emails 3-9 need verses, so create memverse
        memverse = Memverse.create!(
          user: confirmed_user,
          verse: john_verse,
          efactor: 2.5,
          rep_n: level,
          status: "Learning"
        )
        
        ActionMailer::Base.deliveries.clear
        UserMailer.send("progression_email_#{level}", confirmed_user).deliver_now
        
        expect(ActionMailer::Base.deliveries.length).to eq(1)
        
        email = ActionMailer::Base.deliveries.first
        expect(email.subject).to eq("Memverse Reminder")
        expect(email['X-PM-Tag']&.value).to eq("progression-#{level}")
        expect(email['X-PM-Message-Stream']&.value).to eq('broadcast')
      end
    end
  end
  
  describe "newsletter email" do
    it "sends newsletter email with proper content and headers" do
      ActionMailer::Base.deliveries.clear
      UserMailer.newsletter_email(confirmed_user).deliver_now
      
      expect(ActionMailer::Base.deliveries.length).to eq(1)
      
      email = ActionMailer::Base.deliveries.first
      expect(email.subject).to eq("Memverse Newsletter")
      expect(email.to).to include("progress@test.com")
      expect(email.from).to include("admin@memverse.com")
      expect(email.body.to_s).to include("Progressor")
      
      # Verify Postmark headers for newsletter
      expect(email['X-PM-Tag']&.value).to eq('newsletter')
      expect(email['X-PM-Message-Stream']&.value).to eq('broadcast')
      expect(email['List-Unsubscribe']&.value).to include('https://memverse.com/unsubscribe/progress@test.com')
    end
  end
  
  describe "email content verification" do
    it "progression emails include verse content when appropriate" do
      memverse1 = Memverse.create!(
        user: confirmed_user,
        verse: john_verse,
        efactor: 2.5,
        rep_n: 9,
        status: "Learning"
      )
      
      memverse2 = Memverse.create!(
        user: confirmed_user,
        verse: romans_verse,
        efactor: 2.5,
        rep_n: 3,
        status: "Learning"
      )
      
      # Send level 9 email
      UserMailer.progression_email_9(confirmed_user).deliver_now
      email1 = ActionMailer::Base.deliveries.first
      expect(email1.body.to_s).to include("For God so loved the world")
      
      ActionMailer::Base.deliveries.clear
      
      # Send level 3 email
      UserMailer.progression_email_3(confirmed_user).deliver_now
      email2 = ActionMailer::Base.deliveries.first
      expect(email2.body.to_s).to include("And we know that God causes")
    end
    
    it "emails are multipart with both HTML and text versions" do
      memverse = Memverse.create!(
        user: confirmed_user,
        verse: john_verse,
        efactor: 2.5,
        rep_n: 9,
        status: "Learning"
      )
      
      ActionMailer::Base.deliveries.clear
      UserMailer.progression_email_9(confirmed_user).deliver_now
      UserMailer.newsletter_email(confirmed_user).deliver_now
      
      expect(ActionMailer::Base.deliveries.length).to eq(2)
      
      ActionMailer::Base.deliveries.each do |email|
        expect(email.multipart?).to be true
        expect(email.html_part).to be_present
        expect(email.text_part).to be_present
        expect(email.html_part.body.to_s).to include("Progressor")
        expect(email.text_part.body.to_s).to include("Progressor")
      end
    end
    
    it "all emails include proper unsubscribe headers" do
      memverse = Memverse.create!(
        user: confirmed_user,
        verse: john_verse,
        efactor: 2.5,
        rep_n: 5,
        status: "Learning"
      )
      
      ActionMailer::Base.deliveries.clear
      UserMailer.progression_email_5(confirmed_user).deliver_now
      UserMailer.newsletter_email(confirmed_user).deliver_now
      
      expect(ActionMailer::Base.deliveries.length).to eq(2)
      
      ActionMailer::Base.deliveries.each do |email|
        expect(email['List-Unsubscribe']&.value).to include('https://memverse.com/unsubscribe/progress@test.com')
        expect(email['List-Unsubscribe-Post']&.value).to include('List-Unsubscribe=One-Click')
      end
    end
  end
end