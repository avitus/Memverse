require "spec_helper"
require "email_spec"
require "email_spec/rspec"

RSpec.describe "Email Integration", type: :mailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  let(:user) { FactoryBot.create(:user, email: "test@example.com", name: "Test User") }

  before do
    allow(ApplicationSettings).to receive(:config).and_return({ 'url' => 'https://memverse.com' })
  end

  describe "ActionMailer email extensions" do
    describe "#add_postmark_unsubscribe_link" do
      it "sets List-Unsubscribe header" do
        mail = UserMailer.signup_notification(user)
        expected_url = "https://memverse.com/unsubscribe/#{user.email}"
        
        expect(mail.header['List-Unsubscribe'].to_s).to include(expected_url)
      end

      it "sets List-Unsubscribe-Post header" do
        mail = UserMailer.signup_notification(user)
        expect(mail.header['List-Unsubscribe-Post'].to_s).to eq("List-Unsubscribe=One-Click")
      end

      it "does not set headers when user is nil" do
        expect { UserMailer.new.send(:add_postmark_unsubscribe_link, nil) }.not_to raise_error
      end

      it "does not set headers when user email is blank" do
        user_without_email = FactoryBot.build(:user, email: "", name: "No Email User")
        
        expect { UserMailer.new.send(:add_postmark_unsubscribe_link, user_without_email) }.not_to raise_error
      end
    end
  end

  describe "Mailer configuration" do
  end

  describe "Email delivery in test environment" do
    before do
      ActionMailer::Base.deliveries.clear
    end

    it "includes Postmark tag header in delivered emails" do
      mail = UserMailer.signup_notification(user)
      mail.deliver_now

      delivered_mail = ActionMailer::Base.deliveries.last
      expect(delivered_mail.tag).to eq("signup-notification")
    end

    it "includes Postmark message stream in delivered emails" do
      mail = UserMailer.signup_notification(user)
      mail.deliver_now

      delivered_mail = ActionMailer::Base.deliveries.last
      expect(delivered_mail.message_stream).to eq("outbound")
    end
  end

  describe "Email tagging validation" do
    def test_email_tag(method_name, expected_tag, expected_stream = "broadcast")
      test_user = FactoryBot.create(:user, email: "#{method_name}-test@example.com", name: "#{method_name.to_s.titleize} Test User")
      
      # Mock random_verse for progression emails that require it
      if method_name.to_s.include?('progression') && !method_name.to_s.include?('progression_email_2')
        verse = FactoryBot.create(:verse, 
          text: "Test verse for #{method_name}",
          book: "Genesis",
          chapter: 1,
          versenum: 1,
          translation: "NIV"
        )
        memverse = FactoryBot.create(:memverse, user: test_user, verse: verse)
        allow(test_user).to receive(:random_verse).and_return(memverse)
      end
      
      mail = UserMailer.send(method_name, test_user)
      # Check headers without rendering the email body
      expect(mail.tag).to eq(expected_tag)
      expect(mail.message_stream).to eq(expected_stream)
    end

    it "sets correct Postmark tag and message stream for newsletter_email" do
      test_email_tag(:newsletter_email, "newsletter")
    end

    it "sets correct Postmark tag and message stream for progression_email_9" do
      test_email_tag(:progression_email_9, "progression-9", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_8" do
      test_email_tag(:progression_email_8, "progression-8", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_7" do
      test_email_tag(:progression_email_7, "progression-7", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_6" do
      test_email_tag(:progression_email_6, "progression-6", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_5" do
      test_email_tag(:progression_email_5, "progression-5", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_4" do
      test_email_tag(:progression_email_4, "progression-4", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_3" do
      test_email_tag(:progression_email_3, "progression-3", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for progression_email_2" do
      test_email_tag(:progression_email_2, "progression-2", "reminder-stream")
    end

    it "sets correct Postmark tag and message stream for signup_notification" do
      test_email_tag(:signup_notification, "signup-notification", "outbound")
    end

    it "sets correct Postmark tag and message stream for activation" do
      test_email_tag(:activation, "account-activation", "outbound")
    end
  end

  describe "Unsubscribe URL generation" do
    it "generates correct unsubscribe URLs for different users" do
      user1 = FactoryBot.create(:user, email: "user1@test.com")
      user2 = FactoryBot.create(:user, email: "user2@test.com")

      mail1 = UserMailer.signup_notification(user1)
      mail2 = UserMailer.signup_notification(user2)

      expect(mail1.header['List-Unsubscribe'].to_s).to include("user1@test.com")
      expect(mail2.header['List-Unsubscribe'].to_s).to include("user2@test.com")
      expect(mail1.header['List-Unsubscribe'].to_s).not_to include("user2@test.com")
      expect(mail2.header['List-Unsubscribe'].to_s).not_to include("user1@test.com")
    end

    it "handles special characters in email addresses" do
      user_special = FactoryBot.create(:user, email: "user+tag@test.com")
      mail = UserMailer.signup_notification(user_special)
      
      expect(mail.header['List-Unsubscribe'].to_s).to include("user+tag@test.com")
    end
  end

  describe "ApplicationSettings integration" do
    it "uses ApplicationSettings for URL generation" do
      allow(ApplicationSettings).to receive(:config).and_return({ 'url' => 'https://test.memverse.com' })
      
      mail = UserMailer.signup_notification(user)
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://test.memverse.com/unsubscribe")
    end

    it "handles missing ApplicationSettings gracefully" do
      allow(ApplicationSettings).to receive(:config).and_return({})
      
      expect { UserMailer.signup_notification(user) }.not_to raise_error
    end
  end
end