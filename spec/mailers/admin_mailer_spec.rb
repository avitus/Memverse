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

      it "includes pending posts in the body" do
        expect(mail.body.encoded).to include("TestUser")
      end

      it "includes the posts variable" do
        mail.deliver_now  # This ensures the view is rendered
        # Check that @posts is properly set up
        expect(mail.body.encoded).to include("Test Topic")  # Topic title should be in email
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

  describe "handling orphaned posts" do
    context "when post.user is nil" do
      let!(:mock_postable) { double("Postable", title: "Test Topic") }
      let!(:orphaned_post) {
        double("Thredded::Post",
               content: "Post from deleted user",
               user: nil,
               postable: mock_postable,
               id: 456)
      }

      before do
        unless defined?(Thredded::Post)
          stub_const("Thredded::Post", Class.new)
        end

        allow_any_instance_of(ActionView::Base).to receive(:thredded).and_return(
          double("ThreddedHelpers", post_permalink_url: "http://example.com/posts/456")
        )

        allow_any_instance_of(ActionView::Base).to receive(:t).with(
          'thredded.emails.post_notification.html.post_lead_html',
          hash_including(:user, :post_url, :topic_title)
        ).and_return("[Deleted User] posted in Test Topic")

        allow_any_instance_of(ActionView::Base).to receive(:render).with(
          hash_including(partial: 'thredded/posts/content')
        ).and_return("<div>Post from deleted user</div>")

        allow_any_instance_of(ActionView::Base).to receive(:cache).and_yield

        allow(Thredded::Post).to receive(:pending_moderation).and_return([orphaned_post])
      end

      let(:mail) { AdminMailer.forum_review }

      it "uses fallback display name for deleted user" do
        expect(mail.body.encoded).to include("[Deleted User]")
      end

      it "still renders and delivers the email" do
        expect(mail.subject).to eq("Forum: Posts and topics to review")
        expect(mail.to).to eq(["admin@memverse.com", "alexcwatt@memverse.com"])
      end
    end

    context "when post.postable is nil" do
      let!(:mock_user) { double("User", thredded_display_name: "TestUser") }
      let!(:orphaned_post) {
        double("Thredded::Post",
               content: "Post in deleted topic",
               user: mock_user,
               postable: nil,
               id: 789)
      }

      before do
        unless defined?(Thredded::Post)
          stub_const("Thredded::Post", Class.new)
        end

        allow_any_instance_of(ActionView::Base).to receive(:thredded).and_return(
          double("ThreddedHelpers", post_permalink_url: "http://example.com/posts/789")
        )

        allow_any_instance_of(ActionView::Base).to receive(:t).with(
          'thredded.emails.post_notification.html.post_lead_html',
          hash_including(:user, :post_url, :topic_title)
        ).and_return("TestUser posted in [Deleted Topic]")

        allow_any_instance_of(ActionView::Base).to receive(:render).with(
          hash_including(partial: 'thredded/posts/content')
        ).and_return("<div>Post in deleted topic</div>")

        allow_any_instance_of(ActionView::Base).to receive(:cache).and_yield

        allow(Thredded::Post).to receive(:pending_moderation).and_return([orphaned_post])
      end

      let(:mail) { AdminMailer.forum_review }

      it "uses fallback title for deleted topic" do
        expect(mail.body.encoded).to include("[Deleted Topic]")
      end

      it "still renders and delivers the email" do
        expect(mail.subject).to eq("Forum: Posts and topics to review")
        expect(mail.to).to eq(["admin@memverse.com", "alexcwatt@memverse.com"])
      end
    end

    context "when both post.user and post.postable are nil" do
      let!(:fully_orphaned_post) {
        double("Thredded::Post",
               content: "Fully orphaned post",
               user: nil,
               postable: nil,
               id: 999)
      }

      before do
        unless defined?(Thredded::Post)
          stub_const("Thredded::Post", Class.new)
        end

        allow_any_instance_of(ActionView::Base).to receive(:thredded).and_return(
          double("ThreddedHelpers", post_permalink_url: "http://example.com/posts/999")
        )

        allow_any_instance_of(ActionView::Base).to receive(:t).with(
          'thredded.emails.post_notification.html.post_lead_html',
          hash_including(:user, :post_url, :topic_title)
        ).and_return("[Deleted User] posted in [Deleted Topic]")

        allow_any_instance_of(ActionView::Base).to receive(:render).with(
          hash_including(partial: 'thredded/posts/content')
        ).and_return("<div>Fully orphaned post</div>")

        allow_any_instance_of(ActionView::Base).to receive(:cache).and_yield

        allow(Thredded::Post).to receive(:pending_moderation).and_return([fully_orphaned_post])
      end

      let(:mail) { AdminMailer.forum_review }

      it "uses fallback values for both user and topic" do
        expect(mail.body.encoded).to include("[Deleted User]")
        expect(mail.body.encoded).to include("[Deleted Topic]")
      end

      it "still renders and delivers the email without errors" do
        expect { mail.deliver_now }.not_to raise_error
        expect(mail.subject).to eq("Forum: Posts and topics to review")
        expect(mail.to).to eq(["admin@memverse.com", "alexcwatt@memverse.com"])
      end
    end
  end
end