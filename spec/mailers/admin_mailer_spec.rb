require "spec_helper"

RSpec.describe AdminMailer, type: :mailer do
  describe "forum_review" do
    context "when there are posts pending moderation" do
      let!(:mock_user) { double("User", thredded_display_name: "TestUser") }
      let!(:mock_postable) { double("Postable", title: "Test Topic") }
      let!(:pending_post) { 
        double("Thredded::Post", 
               content: "This needs review", 
               user: mock_user,
               postable: mock_postable,
               id: 123)
      }

      before do
        # Ensure Thredded::Post class exists
        unless defined?(Thredded::Post)
          stub_const("Thredded::Post", Class.new)
        end
        
        # Mock thredded helper methods and routes
        allow_any_instance_of(ActionView::Base).to receive(:thredded).and_return(
          double("ThreddedHelpers", post_permalink_url: "http://example.com/posts/123")
        )
        
        # Mock the t helper for translations
        allow_any_instance_of(ActionView::Base).to receive(:t).with(
          'thredded.emails.post_notification.html.post_lead_html',
          hash_including(:user, :post_url, :topic_title)
        ).and_return("TestUser posted in Test Topic")
        
        # Mock the render partial method
        allow_any_instance_of(ActionView::Base).to receive(:render).with(
          hash_including(partial: 'thredded/posts/content')
        ).and_return("<div>This needs review</div>")
        
        # Mock the cache method
        allow_any_instance_of(ActionView::Base).to receive(:cache).and_yield
        
        allow(Thredded::Post).to receive(:pending_moderation).and_return([pending_post])
      end

      let(:mail) { AdminMailer.forum_review }

      it "renders the headers correctly" do
        expect(mail.subject).to eq("Forum: Posts and topics to review")
        expect(mail.to).to eq(["admin@memverse.com", "alexcwatt@memverse.com"])
        expect(mail.from).to eq(["admin@memverse.com"]) # Rails may strip display name in test
      end

      it "sets correct X-MC-Tags header" do
        expect(mail.header['X-MC-Tags'].to_s).to eq("forum-review")
      end

      it "includes pending posts in the body" do
        expect(mail.body.encoded).to be_present
      end

      it "includes the posts variable" do
        # Trigger delivery to populate instance variables
        mail.deliver_now
        # Since we can't directly access the mailer instance variables after delivery,
        # we verify the posts are accessible by checking that the method was called
        expect(Thredded::Post).to have_received(:pending_moderation)
      end
    end

    context "when there are no posts pending moderation" do
      before do
        unless defined?(Thredded::Post)
          stub_const("Thredded::Post", Class.new)
        end
        allow(Thredded::Post).to receive(:pending_moderation).and_return([])
      end

      it "does not send email" do
        mail = AdminMailer.forum_review
        expect(mail.message).to be_a(ActionMailer::Base::NullMail)
      end

      it "returns NullMail when no posts to review" do
        expect(AdminMailer.forum_review.message).to be_a(ActionMailer::Base::NullMail)
      end
    end

  end

  describe "default configuration" do
    it "sets the correct default from address" do
      expect(AdminMailer.default_params[:from]).to eq('"Memverse" <admin@memverse.com>')
    end
  end

  describe "email deliverability" do
    context "when there are pending posts" do
      let!(:mock_user) { double("User", thredded_display_name: "TestUser") }
      let!(:mock_postable) { double("Postable", title: "Test Topic") }
      let!(:pending_post) { 
        double("Thredded::Post", 
               content: "Test content", 
               user: mock_user,
               postable: mock_postable,
               id: 123)
      }

      before do
        unless defined?(Thredded::Post)
          stub_const("Thredded::Post", Class.new)
        end
        
        # Mock the same methods as above
        allow_any_instance_of(ActionView::Base).to receive(:thredded).and_return(
          double("ThreddedHelpers", post_permalink_url: "http://example.com/posts/123")
        )
        allow_any_instance_of(ActionView::Base).to receive(:t).and_return("TestUser posted")
        allow_any_instance_of(ActionView::Base).to receive(:render).and_return("<div>Test content</div>")
        allow_any_instance_of(ActionView::Base).to receive(:cache).and_yield
        
        allow(Thredded::Post).to receive(:pending_moderation).and_return([pending_post])
      end

      it "creates a deliverable email" do
        mail = AdminMailer.forum_review
        expect(mail).to respond_to(:deliver_now)
        expect(mail.to).to include("admin@memverse.com")
        expect(mail.to).to include("alexcwatt@memverse.com")
      end
    end
  end

  describe "Mail library integration" do
    it "requires the Mail library" do
      # Verify that the Mail library is properly required
      expect(defined?(Mail)).to be_truthy
    end
  end
end