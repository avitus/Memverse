require "spec_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { FactoryBot.create(:user, email: "test@example.com", name: "Test User") }
  let(:verse) { FactoryBot.create(:verse, text: "For God so loved the world...") }
  let(:memverse) { FactoryBot.create(:memverse, user: user, verse: verse) }

  before do
    allow(user).to receive(:random_verse).and_return(memverse)
    allow(ApplicationSettings).to receive(:config).and_return({ 'url' => 'https://memverse.com' })
  end

  describe "newsletter_email" do
    let(:mail) { UserMailer.newsletter_email(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Newsletter")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])  # In test environment, the display name might be stripped
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
      expect(mail.header['List-Unsubscribe-Post'].to_s).to eq("List-Unsubscribe=One-Click")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/Hi,/)  # Newsletter template content
    end

    it "sets up email variables correctly" do
      mail_body = mail.body.parts.first.body.raw_source
      expect(mail_body).to include("Memverse.com")  # Check for actual content in newsletter
    end
  end

  describe "progression_email_9" do
    let(:mail) { UserMailer.progression_email_9(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
      expect(mail.header['List-Unsubscribe-Post'].to_s).to eq("List-Unsubscribe=One-Click")
    end

    it "includes verse content and user name" do
      expect(mail.body.encoded).to match(/For God so loved the world/)
      expect(mail.body.encoded).to match(/Test User/)  # User name is included in progression emails
    end
  end

  describe "progression_email_8" do
    let(:mail) { UserMailer.progression_email_8(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "progression_email_7" do
    let(:mail) { UserMailer.progression_email_7(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "progression_email_6" do
    let(:mail) { UserMailer.progression_email_6(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "progression_email_5" do
    let(:mail) { UserMailer.progression_email_5(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "progression_email_4" do
    let(:mail) { UserMailer.progression_email_4(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "progression_email_3" do
    let(:mail) { UserMailer.progression_email_3(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "progression_email_2" do
    let(:mail) { UserMailer.progression_email_2(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Memverse Reminder")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
    end

    it "does not include verse content (no random_verse call)" do
      # This email doesn't call random_verse, so no verse content should be present
      expect(mail.body.encoded).not_to match(/For God so loved the world/)
    end
  end

  describe "signup_notification" do
    let(:mail) { UserMailer.signup_notification(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Welcome to Memverse!")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
      expect(mail.header['List-Unsubscribe-Post'].to_s).to eq("List-Unsubscribe=One-Click")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/test@example.com/)  # Email is included in signup template
    end
  end

  describe "activation" do
    let(:mail) { UserMailer.activation(user) }

    it "renders the headers correctly" do
      expect(mail.subject).to eq("Your Memverse account has been activated!")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["admin@memverse.com"])
    end


    it "includes unsubscribe headers" do
      expect(mail.header['List-Unsubscribe'].to_s).to include("https://memverse.com/unsubscribe/#{user.email}")
      expect(mail.header['List-Unsubscribe-Post'].to_s).to eq("List-Unsubscribe=One-Click")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(/activated/)  # Check for activation content
    end
  end

  describe "setup_email" do
    let(:mail) { UserMailer.newsletter_email(user) }

    before { mail.deliver_now }

    it "sets up email variables correctly" do
      # Access the mailer instance to check instance variables
      mailer = UserMailer.new
      mailer.send(:setup_email, user)
      
      expect(mailer.instance_variable_get(:@user)).to eq(user)
      expect(mailer.instance_variable_get(:@email_with_name)).to eq("#{user.name} <#{user.email}>")
      expect(mailer.instance_variable_get(:@url)).to eq("https://memverse.com")
      expect(mailer.instance_variable_get(:@unsubscribe_url)).to eq("https://memverse.com/unsubscribe/#{user.email}")
    end
  end

  describe "default configuration" do
    it "sets the correct default from address" do
      expect(UserMailer.default_params[:from]).to eq('"Memverse" <admin@memverse.com>')
    end

    it "sets the correct default URL options host" do
      # UserMailer inherits from ActionMailer::Base
      expect(UserMailer.default_url_options[:host]).to eq(ActionMailer::Base.default_url_options[:host])
    end
  end

  describe "email format validation" do
    context "when user has valid email" do
      it "all emails can be delivered" do
        emails = [
          UserMailer.newsletter_email(user),
          UserMailer.progression_email_9(user),
          UserMailer.progression_email_8(user),
          UserMailer.progression_email_7(user),
          UserMailer.progression_email_6(user),
          UserMailer.progression_email_5(user),
          UserMailer.progression_email_4(user),
          UserMailer.progression_email_3(user),
          UserMailer.progression_email_2(user),
          UserMailer.signup_notification(user),
          UserMailer.activation(user)
        ]

        emails.each do |mail|
          expect(mail.to).to eq([user.email])
          expect(mail.from).to eq(["admin@memverse.com"])
          # Mail objects should be valid for delivery
          expect(mail).to respond_to(:deliver_now)
        end
      end
    end

    context "when user has invalid email" do
      let(:user_with_invalid_email) { FactoryBot.build(:user, email: "", name: "Invalid User") }

      it "handles missing email gracefully" do
        # Just building the user (not creating) avoids validation errors
        expect { UserMailer.signup_notification(user_with_invalid_email) }.not_to raise_error
      end
    end
  end

  describe "email formatting with special characters" do
    # Test the format_email_with_name private method directly
    let(:test_mailer) { UserMailer.new }

    before do
      # Make the private method accessible for testing
      UserMailer.send(:public, :format_email_with_name)
    end

    after do
      # Reset to private
      UserMailer.send(:private, :format_email_with_name)
    end

    # Test cases for names that were causing Postmark errors
    [
      { name: "LOUIS RODRIGUEZ JR,", expected: '"LOUIS RODRIGUEZ JR," <test@example.com>' },
      { name: "Douglas E. Heilman, Sr.", expected: '"Douglas E. Heilman, Sr." <test@example.com>' },
      { name: "GlorifyGod<3", expected: '"GlorifyGod<3" <test@example.com>' },
      { name: "Cory(a fool)", expected: '"Cory(a fool)" <test@example.com>' },  # Shortened version
      { name: "Jayko Leonard, secret agent", expected: '"Jayko Leonard, secret agent" <test@example.com>' },
      { name: "FireCracker! ;)", expected: '"FireCracker! ;)" <test@example.com>' },
      { name: "| (˚)(˚) |,.-={Ello}", expected: '"| (˚)(˚) |,.-={Ello}" <test@example.com>' },
      { name: "Ashley Mc <3", expected: '"Ashley Mc <3" <test@example.com>' },
      { name: "R.E. ", expected: '"R.E. " <test@example.com>' },
      { name: nil, expected: "test@example.com" },  # Test nil name
      { name: "", expected: "test@example.com" }    # Test empty name
    ].each do |test_case|
      context "with name '#{test_case[:name]}'" do
        it "formats the email address correctly" do
          # Create a user mock with the test name
          user_mock = double("User", name: test_case[:name], email: "test@example.com", id: 1)

          result = test_mailer.format_email_with_name(user_mock)
          expect(result).to eq(test_case[:expected])
        end
      end
    end

    context "when Mail::Address formatting fails" do
      it "falls back to email-only format and logs warning" do
        user_mock = double("User", name: "Test User", email: "test@example.com", id: 123)

        # Simulate Mail::Address failure
        allow(Mail::Address).to receive(:new).and_raise(StandardError.new("Formatting error"))

        # Expect warning to be logged
        expect(Rails.logger).to receive(:warn).with("Failed to format email with name for user 123: Formatting error")

        result = test_mailer.format_email_with_name(user_mock)
        expect(result).to eq("test@example.com")
      end
    end

    # Integration test with actual email sending
    context "integration with progression emails" do
      let(:user_with_comma) { FactoryBot.create(:user, email: "comma@example.com", name: "John Doe, Jr.", login: "john-doe-jr-test") }
      let(:user_with_special) { FactoryBot.create(:user, email: "special@example.com", name: "User<3", login: "user-heart-test") }

      before do
        allow(user_with_comma).to receive(:random_verse).and_return(memverse)
        allow(user_with_special).to receive(:random_verse).and_return(memverse)
      end

      it "sends email successfully with comma in name" do
        mail = UserMailer.progression_email_9(user_with_comma)
        expect(mail[:to].to_s).to include('"John Doe, Jr."')
        expect(mail[:to].to_s).to include('comma@example.com')
        # Mail object should be valid
        expect(mail).to respond_to(:deliver_now)
      end

      it "sends email successfully with < character in name" do
        mail = UserMailer.progression_email_9(user_with_special)
        expect(mail[:to].to_s).to include('"User<3"')
        expect(mail[:to].to_s).to include('special@example.com')
        # Mail object should be valid
        expect(mail).to respond_to(:deliver_now)
      end
    end
  end
end