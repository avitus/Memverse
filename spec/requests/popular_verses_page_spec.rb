require 'rails_helper'

# A negative ?page= became a negative SQL OFFSET, which MySQL rejects as a
# syntax error, so crawlers probing page numbers got a 500 (Sentry MEMVERSE-9Y).
RSpec.describe "Popular verses pagination", type: :request do
  describe "GET /popular (signed out)" do
    it "treats a negative page as the first page" do
      get "/popular", params: { page: -1 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/Page 1\b/)
    end
  end

  describe "GET /popular_verses (signed in)" do
    before { sign_in FactoryBot.create(:user) }

    it "treats a negative page as the first page" do
      get "/popular_verses", params: { page: -1 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/Page 1\b/)
    end
  end
end
