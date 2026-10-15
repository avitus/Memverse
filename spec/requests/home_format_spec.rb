require 'rails_helper'

# HomeController only has HTML templates. Bots and link previewers that ask
# for JSON used to get a 500 (ActionView::MissingTemplate, Sentry MEMVERSE-9E);
# they should get a 406 Not Acceptable instead, with HTML unchanged.
RSpec.describe "HomeController response formats", type: :request do
  describe "GET / (signed out)" do
    it "renders the HTML landing page" do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end

    it "renders the HTML landing page for a wildcard Accept header" do
      get "/", headers: { "Accept" => "*/*" }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end

    it "returns 406 Not Acceptable when JSON is requested" do
      get "/", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:not_acceptable)
    end
  end

  describe "GET /quick_start (signed in)" do
    before { sign_in FactoryBot.create(:user) }

    it "renders the HTML quick start page" do
      get "/quick_start"
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end

    it "returns 406 Not Acceptable when JSON is requested" do
      get "/quick_start", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
