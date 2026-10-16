require 'rails_helper'

# Actions that rely on implicit render only have HTML templates, so a request
# whose Accept header can't be satisfied raises ActionController::UnknownFormat.
# ApplicationController rescues that app-wide and should answer 406 Not
# Acceptable (not 415, which is about the request body's Content-Type).
RSpec.describe "Unsupported response formats", type: :request do
  describe "GET /supermemo (InfoController#sm_description, implicit render)" do
    it "renders the HTML page" do
      get "/supermemo"
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end

    it "returns 406 Not Acceptable with an empty body when JSON is requested" do
      get "/supermemo", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:not_acceptable)
      expect(response.body).to be_empty
    end
  end
end
