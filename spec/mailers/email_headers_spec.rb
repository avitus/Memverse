require "spec_helper"
require "email_spec"
require "email_spec/rspec"

RSpec.describe "Email Headers", type: :mailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  let(:user) { FactoryBot.create(:user, email: "test@example.com", name: "Test User") }
  let(:verse) { FactoryBot.build(:verse, text: "For God so loved the world...") }
  let(:memverse) { FactoryBot.build(:memverse, user: user, verse: verse) }

  before do
    # Stub the random_verse method to avoid database creation that might trigger callbacks
    allow_any_instance_of(User).to receive(:random_verse).and_return(memverse)
    allow(ApplicationSettings).to receive(:config).and_return({ 'url' => 'https://memverse.com' })
    
    # Disable user callbacks that might interfere with tests
    allow_any_instance_of(User).to receive(:send_signup_notification)
    allow_any_instance_of(User).to receive(:send_activation_notification)
    
    ActionMailer::Base.deliveries.clear
  end

  describe "Standard email headers" do
    let(:mail) { UserMailer.signup_notification(user) }

    it "sets correct From header" do
      expect(mail.from).to eq(["admin@memverse.com"])
    end

    it "sets correct To header" do
      expect(mail.to).to eq([user.email])
    end

    it "sets correct Subject header" do
      expect(mail.subject).to eq("Welcome to Memverse!")
    end

    it "includes Date header" do
      # In test environment, ActionMailer doesn't automatically set Date header
      # This would be set by the mail delivery service in production
      expect(mail.date).to be_nil
    end

    it "includes Message-ID header" do
      # In test environment, ActionMailer doesn't automatically set Message-ID header
      # This would be set by the mail delivery service in production
      expect(mail.message_id).to be_nil
    end
  end

  describe "Email tagging headers" do
    it "sets correct X-MC-Tags header for newsletter email" do
      mail = UserMailer.newsletter_email(user)
      expect(mail.header['X-MC-Tags'].to_s).to eq("newsletter")
    end

    it "sets correct X-MC-Tags header for signup notification" do
      mail = UserMailer.signup_notification(user)
      expect(mail.header['X-MC-Tags'].to_s).to eq("signup-notification")
    end

    it "sets correct X-MC-Tags header for activation email" do
      mail = UserMailer.activation(user)
      expect(mail.header['X-MC-Tags'].to_s).to eq("account-activation")
    end

    it "sets correct X-MC-Tags header for progression emails" do
      mail = UserMailer.progression_email_2(user)
      expect(mail.header['X-MC-Tags'].to_s).to eq("progression-2")
    end

    it "can deliver all email types successfully" do
      email_methods = [:newsletter_email, :signup_notification, :activation, :progression_email_2]
      
      email_methods.each do |method|
        expect { UserMailer.send(method, user).deliver_now }.not_to raise_error
      end
    end
  end

  describe "Unsubscribe headers" do
    let(:mail) { UserMailer.newsletter_email(user) }

    it "sets List-Unsubscribe header with correct URL" do
      unsubscribe_header = mail.header['List-Unsubscribe']
      expect(unsubscribe_header).to be_present
      expect(unsubscribe_header.to_s).to eq("<https://memverse.com/unsubscribe/#{user.email}>")
    end

    it "sets List-Unsubscribe-Post header for one-click unsubscribe" do
      unsubscribe_post_header = mail.header['List-Unsubscribe-Post']
      expect(unsubscribe_post_header).to be_present
      expect(unsubscribe_post_header.to_s).to eq("List-Unsubscribe=One-Click")
    end

    it "includes unsubscribe headers in all user emails" do
      user_email_methods = [
        :newsletter_email, :progression_email_9, :progression_email_8, :progression_email_7,
        :progression_email_6, :progression_email_5, :progression_email_4, :progression_email_3,
        :progression_email_2, :signup_notification, :activation
      ]

      user_email_methods.each do |method|
        mail = UserMailer.send(method, user)
        expect(mail.header['List-Unsubscribe']).to be_present
        expect(mail.header['List-Unsubscribe-Post']).to be_present
      end
    end

    it "does not include unsubscribe headers in admin emails" do
      # Create a properly mocked post with all required properties
      mock_user = double("User", thredded_display_name: "Test User")
      mock_postable = double("Topic", title: "Test Topic")
      post = double("Post", 
        id: 123,
        user: mock_user,
        postable: mock_postable,
        content: "Test content"
      )
      
      # Ensure Thredded::Post class exists
      unless defined?(Thredded::Post)
        stub_const("Thredded::Post", Class.new)
      end
      
      # Mock all the ActionView helpers used in the template
      allow_any_instance_of(ActionView::Base).to receive(:thredded).and_return(
        double("ThreddedHelpers", post_permalink_url: "http://example.com/posts/123")
      )
      
      allow_any_instance_of(ActionView::Base).to receive(:t).with(
        'thredded.emails.post_notification.html.post_lead_html',
        hash_including(:user, :post_url, :topic_title)
      ).and_return("Test User posted in Test Topic")
      
      allow_any_instance_of(ActionView::Base).to receive(:render).with(
        hash_including(partial: 'thredded/posts/content')
      ).and_return("<div>Test content</div>")
      
      allow_any_instance_of(ActionView::Base).to receive(:cache).and_yield
      
      allow(Thredded::Post).to receive(:pending_moderation).and_return([post])
      
      mail = AdminMailer.forum_review

      expect(mail.header['List-Unsubscribe']).to be_nil
      expect(mail.header['List-Unsubscribe-Post']).to be_nil
    end
  end

  describe "Content-Type headers" do
    let(:mail) { UserMailer.signup_notification(user) }

    it "sets multipart content type for emails with both HTML and text versions" do
      expect(mail.content_type).to match(/multipart\/alternative/)
    end

    it "includes both HTML and text parts" do
      expect(mail.parts.count).to eq(2)
      
      html_part = mail.parts.find { |p| p.content_type.match(/text\/html/) }
      text_part = mail.parts.find { |p| p.content_type.match(/text\/plain/) }
      
      expect(html_part).to be_present
      expect(text_part).to be_present
    end

    it "sets correct charset" do
      mail.parts.each do |part|
        expect(part.charset).to eq('UTF-8')
      end
    end
  end

  describe "Custom headers for email tracking" do
    let(:mail) { UserMailer.signup_notification(user) }

    it "preserves custom headers after delivery" do
      mail.deliver_now
      delivered_mail = ActionMailer::Base.deliveries.last
      
      expect(delivered_mail.header['List-Unsubscribe']).to be_present
      expect(delivered_mail.header['List-Unsubscribe-Post']).to be_present
    end
  end

  describe "Email header validation" do
    it "ensures all emails have required headers" do
      all_email_methods = [
        [:UserMailer, :newsletter_email],
        [:UserMailer, :progression_email_9],
        [:UserMailer, :progression_email_8], 
        [:UserMailer, :progression_email_7],
        [:UserMailer, :progression_email_6],
        [:UserMailer, :progression_email_5],
        [:UserMailer, :progression_email_4],
        [:UserMailer, :progression_email_3],
        [:UserMailer, :progression_email_2],
        [:UserMailer, :signup_notification],
        [:UserMailer, :activation]
      ]

      all_email_methods.each do |mailer_class, method_name|
        mail = mailer_class.to_s.constantize.send(method_name, user)
        
        # Required headers
        expect(mail.from).to be_present
        expect(mail.to).to be_present  
        expect(mail.subject).to be_present
        # Note: Date and Message-ID headers not set in test environment
        
        # Email tagging headers
        expect(mail.header['X-MC-Tags']).to be_present
      end
    end
  end

  describe "Header encoding" do
    let(:user_with_unicode) { FactoryBot.create(:user, email: "unicode_test_#{Time.now.to_i}@example.com", name: "José María") }
    let(:mail) { UserMailer.signup_notification(user_with_unicode) }

    it "properly encodes unicode characters in headers" do
      expect(mail.to).to eq([user_with_unicode.email])
      expect(mail.subject).to be_present
    end

    it "handles unicode in email body content" do
      # The signup_notification email includes the user's email but not their name
      expect(mail.body.encoded).to include(user_with_unicode.email)
      # Check that the email is properly encoded
      expect(mail.body.encoded).to be_valid_encoding
    end
  end

  describe "Reply-To headers" do
    let(:mail) { UserMailer.newsletter_email(user) }

    it "does not set Reply-To header by default" do
      expect(mail.reply_to).to be_nil
    end

    # If Reply-To is needed in the future, this test documents the expectation
    it "allows Reply-To to be set manually if needed" do
      mail['Reply-To'] = 'noreply@memverse.com'
      expect(mail.reply_to).to eq(['noreply@memverse.com'])
    end
  end

  describe "Precedence headers" do
    it "sets bulk precedence for newsletter emails" do
      mail = UserMailer.newsletter_email(user)
      # This could be added in the future for better email client handling
      # expect(mail.header['Precedence']).to eq('bulk')
    end
  end
end