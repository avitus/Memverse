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
    expect(response.headers["Retry-After"].to_i).to be_between(1, 600)
    expect(response.body).to include("Too many requests")
  end

  it "keeps a tracking-only query string on the ordinary blog limit" do
    31.times { get "/blog?utm_source=newsletter" }
    expect(response).to have_http_status(:ok)
  end

  it "counts HEAD requests against the limit" do
    30.times { head "/blog?page=2" }
    head "/blog?page=2"
    expect(response).to have_http_status(:too_many_requests)
  end

  it "throttles any forum or blog traffic after 120 requests from one IP" do
    120.times do
      get "/forum"
      expect(response).not_to have_http_status(:too_many_requests)
    end

    get "/forum"

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"].to_i).to be_between(1, 600)
  end

  it "keys the limit on the forwarded client when the request comes through the trusted proxy" do
    via_proxy = ->(client) { { "REMOTE_ADDR" => "192.241.205.154", "X-Forwarded-For" => client } }

    30.times { get "/blog?page=2", headers: via_proxy.call("203.0.113.10") }

    get "/blog?page=2", headers: via_proxy.call("203.0.113.20")
    expect(response).not_to have_http_status(:too_many_requests)

    get "/blog?page=2", headers: via_proxy.call("203.0.113.10")
    expect(response).to have_http_status(:too_many_requests)
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
