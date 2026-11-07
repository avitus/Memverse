require 'rails_helper'

RSpec.describe 'Heritage staging pages', type: :request do
  around do |example|
    original = ENV['MEMVERSE_HERITAGE']
    ENV['MEMVERSE_HERITAGE'] = '1'
    example.run
  ensure
    ENV['MEMVERSE_HERITAGE'] = original
  end

  it 'renders real authentication forms with accessible password controls' do
    {
      new_user_session_path => ['Sign in.', '/users/sign_in'],
      new_user_registration_path => ['Create your account.', '/users'],
      new_user_password_path => ['Forgot your password?', '/users/password'],
      new_user_confirmation_path => ['Confirm your email.', '/users/confirmation']
    }.each do |path, (heading, action)|
      get path
      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css('#auth-title').text).to eq(heading)
      expect(document.at_css('form.heritage-auth-form')['action']).to eq(action)
      expect(document.at_css('label[for="user_email"]')).to be_present
      expect(document.css('a[href*="designs.magicpath"]')).to be_empty
    end
  end

  it 'preserves reset tokens and displays invalid confirmation feedback' do
    get edit_user_password_path, params: { reset_password_token: 'sample-token' }
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('input[name="user[reset_password_token]"]')['value']).to eq('sample-token')
    get user_confirmation_path, params: { confirmation_token: 'invalid-token' }
    expect(response.body).to include('Confirmation token is invalid', 'Confirm your email.')
  end

  it 'renders signed-in pages using the user’s data and existing form actions' do
    user = FactoryBot.create(:user, confirmed_at: Time.current)
    FactoryBot.create(:memverse, user: user)
    FactoryBot.create(:progress_report, user: user)
    sign_in user
    [test_verse_quick_path, manage_verses_path, add_verse_path, progress_path, update_profile_path, edit_user_registration_path, user_path(user), passage_review_path].each do |path|
      get path
      expect(response).to have_http_status(:ok), "#{path}: #{response.status}"
      expect(response.body).to include('mv-heritage', 'heritage_application', 'heritage-footer')
      expect(response.body).not_to include('designs.magicpath.ai', 'Experimental - Use with Caution!')
      expect(response.body).to include('data-heritage-collection') if path == manage_verses_path
      expect(response.body).to include('heritage-progress') if path == progress_path
      expect(response.body).to include('heritage-discovery-guide', 'data-verse-suggestion="Psalm 23"') if path == add_verse_path
    end
  end
  it 'renders article excerpts and full articles with native comment links' do
    author = FactoryBot.create(:user, admin: true)
    blog = Bloggity::Blog.create!(title: 'Memverse Blog', url_identifier: 'main')
    post = Bloggity::BlogPost.create!(blog: blog, posted_by: author, title: 'Remembering Scripture',
      body: '<p>' + ('Scripture is a lasting treasure. ' * 20) + '</p>', fck_created: true, is_complete: true)
    get "/blog/#{blog.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Words for the journey.', 'Remembering Scripture', 'Read article')
    get "/blog/#{blog.id}/#{post.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(post.body)
    expect(response.body).not_to include('addthis_widget.js')
  end

  it 'uses the shared design at the public entry point and preserves the legacy fallback' do
    get '/'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Treasure God’s word.', 'heritage_application', 'heritage-header', 'heritage-footer')
    expect(response.body).not_to include('id="narrow-login"', 'id="banner-bg"')
    document = Nokogiri::HTML(response.body)
    expect(document.css('.how-grid article').length).to eq(3)
    expect(document.at_css('.sample-visual')).to be_present
    expect(document.at_css('#heritage-demo-answer')['aria-label']).to eq('Missing word in Psalm 23:1')
    expect(document.at_css('[data-demo-continue]')['href']).to eq(new_user_registration_path)
    expect(document.at_css('nav[aria-label="Main navigation"]').text).to include('How it works', 'Community')
    ENV['MEMVERSE_HERITAGE'] = '0'
    get '/'
    expect(response.body).to include('id="narrow-login"')
    expect(response.body).not_to include('heritage_application')
  end

  it 'uses the shared design on the signed-in home page and links Review to passage review' do
    user = FactoryBot.create(:user, confirmed_at: Time.current)
    verse = FactoryBot.create(:memverse, user: user, next_test: Date.yesterday)
    FactoryBot.create(:progress_report, user: user, entry_date: Date.current, memorized: 7, session_complete: true)
    other_user = FactoryBot.create(:user)
    FactoryBot.create(:progress_report, user: other_user, entry_date: Date.current, memorized: 999)
    allow(Devotion).to receive(:daily_refresh).and_return(nil)
    sign_in user
    get '/'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('heritage-today-review', 'heritage_application')
    expect(response.body).not_to include('home-page-tabs', 'yellow-icon')
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('.heritage-review-queue').text).to include(verse.verse.ref)
    expect(document.at_css('.heritage-retained details').text).to include('7 verses memorized')
    expect(document.at_css('.heritage-retained details').text).not_to include('999')
    expect(document.css('.heritage-week .done').length).to eq(1)
    expect(document.at_css('.heritage-history polyline')['points']).not_to match(/NaN|Infinity/)
    expect(document.at_css('.heritage-collection-ribbon').text).to include('1 total verses')
    navigation = Nokogiri::HTML(response.body).at_css('nav[aria-label="Main navigation"]')
    expect(navigation.css('a').find { |link| link.text == 'Review' }['href']).to eq(passage_review_path)
    expect(navigation.css('a').find { |link| link.text == 'Today' }['href']).to eq(root_path)
    sign_in FactoryBot.create(:user, confirmed_at: Time.current, translation: 'KJV')
    get '/'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Start with a collection of popular verses', starter_pack_path(translation: 'NIV'))
  end

  it 'renders the canvas blog browse, category, tag, and archive states' do
    author = FactoryBot.create(:user, admin: true)
    blog = Bloggity::Blog.create!(title: 'Memverse Blog', url_identifier: 'main')
    category = Bloggity::BlogCategory.create!(name: 'Memorization', blog: blog)
    post = Bloggity::BlogPost.create!(blog: blog, posted_by: author, title: 'Scripture practice', body: 'A lasting treasure.', category: category, is_complete: true)
    allow(Bloggity::BlogPost).to receive(:search).and_return([post])
    get '/blog/blog_search', params: {search_param: 'Scripture'}
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Browse and search.', 'Scripture practice', 'heritage-blog-search')
    get "/blog/#{blog.id}", params: {category_id: category.id}
    expect(Nokogiri::HTML(response.body).at_css('h1').text).to eq('Memorization')
    category_link = Nokogiri::HTML(response.body).css('#side_nav_container a').find { |link| link.text == category.name }
    expect(category_link['href']).to include("category_id=#{category.id}")
    get "/blog/#{blog.id}", params: {tag_name: 'Memory'}
    expect(Nokogiri::HTML(response.body).at_css('h1').text).to eq('Articles tagged “Memory”.')
    get "/blog/#{blog.id}", params: {page: 2}
    expect(Nokogiri::HTML(response.body).at_css('h1').text).to eq('From the archives.')
  end

end
