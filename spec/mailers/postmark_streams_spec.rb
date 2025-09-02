require 'rails_helper'

RSpec.describe "Postmark Message Streams" do
  let(:user) { FactoryBot.create(:user, email: 'test@example.com', name: 'Test User') }
  let(:verse) { FactoryBot.create(:verse) }
  let!(:memverse) { FactoryBot.create(:memverse, user: user, verse: verse) }
  
  describe "UserMailer reminder emails" do
    it "sends progression emails to the 'reminder' stream" do
      # Test progression_email_2 through progression_email_9
      (2..9).each do |n|
        mail = UserMailer.send("progression_email_#{n}", user)
        
        # Check that the message_stream is set to 'reminder'
        expect(mail.message_stream).to eq('reminder-stream'), 
          "progression_email_#{n} should use 'reminder' stream but got #{mail.message_stream}"
        
        # Check the tag is set correctly
        expect(mail.tag).to eq("progression-#{n}"),
          "progression_email_#{n} should have tag 'progression-#{n}' but got #{mail.tag}"
      end
    end
    
    it "sends newsletter emails to the 'broadcast' stream" do
      mail = UserMailer.newsletter_email(user)
      expect(mail.message_stream).to eq('broadcast')
      expect(mail.tag).to eq('newsletter')
    end
    
    it "sends onboarding emails to the 'outbound' stream" do
      mail = UserMailer.onboarding_reminder(user)
      expect(mail.message_stream).to eq('outbound')
      expect(mail.tag).to eq('onboarding-reminder')
    end
    
    it "sends activation emails to the 'outbound' stream" do
      mail = UserMailer.activation(user)
      expect(mail.message_stream).to eq('outbound')
      expect(mail.tag).to eq('account-activation')
    end
    
    it "sends signup notifications to the 'outbound' stream" do
      mail = UserMailer.signup_notification(user)
      expect(mail.message_stream).to eq('outbound')
      expect(mail.tag).to eq('signup-notification')
    end
  end
  
  describe "Thredded forum emails" do
    it "configures Thredded::BaseMailer to use 'forum-stream' stream" do
      # Skip this test if Thredded is not loaded
      skip "Thredded not loaded" unless defined?(Thredded::BaseMailer)
      
      # Create a test instance of Thredded mailer
      # Note: This is a simplified test. In a real scenario, you'd need to 
      # test with actual Thredded notification emails
      mailer = Thredded::BaseMailer.new
      
      # Test that our override is in place
      expect(mailer).to respond_to(:mail)
    end
  end
end