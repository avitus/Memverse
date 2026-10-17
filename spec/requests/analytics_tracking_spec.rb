require 'rails_helper'

# Server-side Ahoy analytics: page views from the AnalyticsTracking concern and
# product events from the controllers. See documentation/ANALYTICS.md.
RSpec.describe "Analytics tracking (Ahoy)", type: :request do
  include BrowserUserAgent

  let(:user) { FactoryBot.create(:user) }

  def page_views
    Ahoy::Event.where(name: "$view")
  end

  def events(name)
    Ahoy::Event.where(name: name)
  end

  describe "page views" do
    it "records a $view event with controller, action and path for an HTML page" do
      expect { get "/faq" }.to(change { page_views.count }.by(1))

      event = page_views.last
      expect(event.properties).to include("controller" => "info", "action" => "faq", "path" => "/faq")
      expect(event.visit).to be_present
      expect(event.visit.landing_page).to end_with("/faq")
    end

    it "stores the landing page and referrer without query strings but keeps utm values" do
      get "/faq?confirmation_token=secret123&utm_source=newsletter",
          headers: { "Referer" => "https://www.example.com/users/password/edit?reset_password_token=abc" }

      visit = page_views.last.visit
      expect(visit.landing_page).to end_with("/faq")
      expect(visit.landing_page).not_to include("secret123")
      expect(visit.referrer).to eq("https://www.example.com/users/password/edit")
      expect(visit.utm_source).to eq("newsletter")
    end

    it "attributes the view and the visit to the signed-in user" do
      sign_in user
      get "/faq"

      event = page_views.last
      expect(event.user_id).to eq(user.id)
      expect(event.visit.user_id).to eq(user.id)
    end

    it "ignores crawlers" do
      expect do
        get "/faq", headers: { "User-Agent" => "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" }
      end.not_to(change { Ahoy::Event.count })
    end

    it "ignores requests with no user agent" do
      expect { get "/faq", headers: { "User-Agent" => "" } }.not_to(change { Ahoy::Event.count })
    end

    it "ignores admin pages and creates no visit for them" do
      sign_in FactoryBot.create(:user, admin: true)
      expect { get "/admin/dashboard" }.not_to(change { [page_views.count, Ahoy::Visit.count] })
      expect(response).to have_http_status(:ok)
    end

    it "ignores XHR requests" do
      expect { get "/faq", xhr: true }.not_to(change { page_views.count })
    end

    it "ignores redirects" do
      expect { get "/manage_verses" }.not_to(change { page_views.count })
      expect(response).to be_redirect
    end
  end

  describe "product events" do
    before { sign_in user }

    it "records signed_up when a registration succeeds" do
      sign_out user
      params = { name: "New Member", email: "new.member@example.com", password: "please", password_confirmation: "please" }

      expect { post user_registration_path, params: { user: params } }.to(change { events("signed_up").count }.by(1))

      event = events("signed_up").last
      new_user = User.find_by(email: "new.member@example.com")
      expect(event.user_id).to eq(new_user.id)
      expect(event.properties["user_id"]).to eq(new_user.id)
    end

    it "starts a fresh visit for the new account when the browser carried another user's visit" do
      get "/faq"
      previous_visit = Ahoy::Visit.last
      expect(previous_visit.user_id).to eq(user.id)
      sign_out user

      params = { name: "Switcher", email: "switcher@example.com", password: "please", password_confirmation: "please" }
      post user_registration_path, params: { user: params }

      event = events("signed_up").last
      new_user = User.find_by(email: "switcher@example.com")
      expect(event.visit).not_to eq(previous_visit)
      expect(event.visit.user_id).to eq(new_user.id)
      expect(previous_visit.reload.user_id).to eq(user.id)
    end

    it "still completes sign-up when analytics storage fails" do
      sign_out user
      allow_any_instance_of(Ahoy::Tracker).to receive(:track).and_raise(ActiveRecord::StatementInvalid, "ahoy down")
      params = { name: "Resilient", email: "resilient@example.com", password: "please", password_confirmation: "please" }

      post user_registration_path, params: { user: params }

      expect(response).to be_redirect
      expect(User.find_by(email: "resilient@example.com")).to be_present
    end

    it "does not record signed_up when registration fails" do
      sign_out user
      expect do
        post user_registration_path, params: { user: { email: "", password: "x", password_confirmation: "y" } }
      end.not_to(change { events("signed_up").count })
    end

    it "records verse_added, flagging the user's first verse" do
      first_verse  = FactoryBot.create(:verse)
      second_verse = FactoryBot.create(:verse2)

      expect { post "/add/#{first_verse.id}" }.to(change { events("verse_added").count }.by(1))
      expect(events("verse_added").last.properties).to include("verse_id" => first_verse.id, "first_verse" => true)

      post "/add/#{second_verse.id}"
      expect(events("verse_added").last.properties).to include("verse_id" => second_verse.id, "first_verse" => false)
    end

    it "does not record verse_added when the verse was already added" do
      verse = FactoryBot.create(:verse)
      post "/add/#{verse.id}"

      expect { post "/add/#{verse.id}" }.not_to(change { events("verse_added").count })
      expect(JSON.parse(response.body)["msg"]).to eq("Previously Added")
    end

    it "records verse_rated with the rating" do
      mv = FactoryBot.create(:memverse, user: user)

      expect { get "/mark_test_quick", params: { mv: mv.id, q: 4 } }.to(change { events("verse_rated").count }.by(1))

      event = events("verse_rated").last
      expect(event.user_id).to eq(user.id)
      expect(event.properties).to include("memverse_id" => mv.id, "verse_id" => mv.verse_id, "rating" => 4)
      expect(event.properties).to have_key("newly_memorized")
    end

    it "does not record verse_rated for another user's verse" do
      mv = FactoryBot.create(:memverse)

      expect { get "/mark_test_quick", params: { mv: mv.id, q: 4 } }.not_to(change { events("verse_rated").count })
    end

    it "does not score or record a reference test for another user's verse" do
      mv = FactoryBot.create(:memverse, ref_interval: 6)

      expect { post "/score_ref/#{mv.id}/10" }.not_to(change { events("reference_tested").count })
      expect(mv.reload.ref_interval).to eq(6)
      expect(JSON.parse(response.body)["msg"]).to match(/belongs to another user/)
    end

    it "records reference_tested with whether the answer was correct" do
      mv = FactoryBot.create(:memverse, user: user)

      expect { post "/score_ref/#{mv.id}/10" }.to(change { events("reference_tested").count }.by(1))
      expect(events("reference_tested").last.properties).to include("memverse_id" => mv.id, "correct" => true)

      post "/score_ref/#{mv.id}/0"
      expect(events("reference_tested").last.properties).to include("correct" => false)
    end
  end
end
