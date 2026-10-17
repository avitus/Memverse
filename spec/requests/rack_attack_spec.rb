require 'rails_helper'

# Backstop throttling for crawlers that walk /blog and /forum exhaustively.
# See config/initializers/rack_attack.rb and documentation/ANALYTICS.md.
RSpec.describe "Rack::Attack crawler throttling", type: :request do
  include BrowserUserAgent

  before { Bloggity::Blog.create!(id: 9, title: "Memverse Blog", subtitle: "News and updates", url_identifier: "main") }

  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    example.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  it "throttles blog listing permutations after 30 requests from one IP" do
    30.times do
      get "/blog?page=2"
      expect(response).not_to have_http_status(:too_many_requests)
    end

    get "/blog?page=2"

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("600")
    expect(response.body).to include("Too many requests")
  end

  it "throttles any forum or blog traffic after 120 requests from one IP" do
    120.times do
      get "/forum"
      expect(response).not_to have_http_status(:too_many_requests)
    end

    get "/forum"

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("600")
  end

  it "does not throttle pages outside /blog and /forum" do
    31.times { get "/faq" }
    expect(response).to have_http_status(:ok)
  end

  it "stays disabled in the test environment by default" do
    Rack::Attack.enabled = false
    31.times { get "/blog?page=2" }
    expect(response).not_to have_http_status(:too_many_requests)
  end
end
