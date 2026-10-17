require 'rails_helper'

# Crawl-noise pages carry noindex, nofollow as both a header and a meta tag.
# See app/controllers/concerns/robots_directives.rb and documentation/ANALYTICS.md.
RSpec.describe "Robots directives", type: :request do
  include BrowserUserAgent

  let(:noindex) { "noindex, nofollow" }

  before { Bloggity::Blog.create!(id: 9, title: "Memverse Blog", subtitle: "News and updates", url_identifier: "main") }

  def robots_meta
    response.body[/<meta name="robots" content="([^"]*)"/, 1]
  end

  it "leaves the landing page indexable" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to be_nil
  end

  it "leaves ordinary pages indexable" do
    get "/faq"

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to be_nil
    expect(robots_meta).to eq("all")
  end

  it "leaves the top-level blog indexable" do
    get "/blog"

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to be_nil
    expect(robots_meta).to eq("all")
  end

  it "marks paginated blog listings noindex" do
    get "/blog?page=2"

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to eq(noindex)
    expect(robots_meta).to eq(noindex)
  end

  it "marks tagged blog listings noindex" do
    get "/blog?tag_name=Bible%20Bee"

    expect(response.headers["X-Robots-Tag"]).to eq(noindex)
  end

  it "leaves a blog listing with only tracking parameters indexable" do
    get "/blog?utm_source=newsletter"

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to be_nil
    expect(robots_meta).to eq("all")
  end

  it "marks forum post permalinks noindex, including the redirect to the topic" do
    author = FactoryBot.create(:user, :approved)
    topic  = FactoryBot.create(:topic, user: author)
    post   = FactoryBot.create(:post, user: author, postable: topic, messageboard: topic.messageboard)

    get "/forum/posts/#{post.id}"

    expect(response).to have_http_status(:found)
    expect(response.headers["X-Robots-Tag"]).to eq(noindex)
  end

  it "leaves forum topic pages indexable" do
    author = FactoryBot.create(:user, :approved)
    topic  = FactoryBot.create(:topic, user: author, with_posts: 1)

    get "/forum/#{topic.messageboard.slug}/#{topic.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to be_nil
    expect(robots_meta).to eq("all")
  end

  it "marks paginated forum topic lists noindex" do
    author = FactoryBot.create(:user, :approved)
    topic  = FactoryBot.create(:topic, user: author, with_posts: 1)

    get "/forum/#{topic.messageboard.slug}/page-2"

    expect(response.headers["X-Robots-Tag"]).to eq(noindex)
  end
end
