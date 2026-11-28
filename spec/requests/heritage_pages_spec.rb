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
      if path == passage_review_path
        document = Nokogiri::HTML(response.body)
        expect(document.css('.upcoming-passages').length).to eq(1)
        expect(document.at_css('.heritage-review-header .heritage-passage-picker')).to be_present
        expect(document.at_css('.heritage-passage-heading h1.passage-title')).to be_present
        picker = document.at_css('details.heritage-passage-picker')
        expect(picker['open']).to be_nil
        expect(picker.at_css('summary').text).to eq('Passages')
        expect(picker.at_css('.upcoming-passages')).to be_present
      end
      expect(response.body).to include('heritage-progress') if path == progress_path
      if path == add_verse_path
        root = Nokogiri::HTML(response.body).at_css('#heritage-add-verse')
        expect(root['data-translation']).to be_present
        expect(JSON.parse(root['data-owned']).size).to eq(1)
        expect(response.body).to include('heritage_add_verse')
      end
    end
  end

  it 'omits self-navigation, preserves the legacy detail, and limits personal controls to the owner' do
    mv = FactoryBot.create(:memverse)
    sign_in mv.user
    get memory_verse_path(mv)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('.verse-neighbors')).to be_nil
    expect(document.at_css('.verse-tag-editor')).to be_present
    expect(document.at_css('.verse-tag-group.community form')).to be_nil

    sign_out mv.user
    sign_in FactoryBot.create(:user, confirmed_at: Time.current)
    get memory_verse_path(mv)
    expect(Nokogiri::HTML(response.body).css('.verse-detail form')).to be_empty
    expect(response.body).to include('Personal tags')

    ENV['MEMVERSE_HERITAGE'] = '0'
    get memory_verse_path(mv)
    expect(Nokogiri::HTML(response.body).at_css('#show-verse').text.strip).to eq(mv.verse.text)
  end

  it 'preserves the schedule and restores the interval-based status after repeated pause requests' do
    mv = FactoryBot.create(:memverse)
    mv.update_columns(status: 'Memorized', test_interval: 35)
    sign_in mv.user
    2.times { post toggle_mv_status_path(mv), params: { review_state: 'paused' } }
    expect(mv.reload.status).to eq('Pending')
    post toggle_mv_status_path(mv), params: { review_state: 'active' }
    expect(response).to redirect_to(memory_verse_path(mv, anchor: 'review-schedule'))
    expect(mv.reload.status).to eq('Memorized')
    expect(mv.test_interval).to eq(35)
    get toggle_mv_status_path(mv, format: :json)
    expect(response.parsed_body).to eq('mv_status' => 'Pending')
  end

  it 'lets a tag administrator add a community tag from the detail page' do
    mv = FactoryBot.create(:memverse, verse: FactoryBot.create(:verse, chapter: 121))
    mv.user.roles << Role.find_or_create_by!(name: 'admin')
    sign_in mv.user
    get memory_verse_path(mv)
    expect(Nokogiri::HTML(response.body).at_css('.community .verse-tag-editor form')['action']).to eq(add_verse_tag_verses_path)
    post add_verse_tag_verses_path, params: { id: mv.verse_id, memory_verse_id: mv.id, value: 'Creation' }
    expect(response).to redirect_to(memory_verse_path(mv, anchor: 'verse-tags'))
    expect(mv.verse.reload.tags.pluck(:name)).to include('Creation')
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

  it 'shows the signed-in account’s due reviews, streak and collection progress' do
    user = FactoryBot.create(:user, confirmed_at: Time.current, all_refs: true)
    verse = FactoryBot.create(:memverse, user: user)
    verse.update_columns(status: 'Memorized', next_test: Date.yesterday, next_ref_test: nil)
    FactoryBot.create(:progress_report, user: user, entry_date: Date.today, session_complete: true)
    FactoryBot.create(:memverse)
    sign_in user
    get '/'
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    home = document.at_css('.heritage-review-home')
    expect(home.at_css('h1').text).to eq('Today’s review')
    expect(home.css('a.review-card').map { |a| [a['aria-label'], a['href']] }).to eq([
      ['Review 1 verse due today', passage_review_path],
      ['Review 1 reference due today', test_ref_path]
    ])
    expect(home.at_css('.first-due')['href']).to eq(passage_review_path)
    expect(home.css('dd').map { |dd| dd.text.squish }).to eq(['1 day', '1 of 1'])
    expect(%w[value max].map { |key| home.at_css('progress')[key] }).to eq(%w[1 1])
    navigation = document.at_css('nav[aria-label="Main navigation"]')
    expect(navigation.css('a').find { |link| link.text == 'Review' }['href']).to eq(passage_review_path)
    expect(navigation.css('a').find { |link| link.text == 'Today' }['href']).to eq(root_path)

    verse.update_columns(next_test: Date.tomorrow)
    get '/'
    home = Nokogiri::HTML(response.body).at_css('.heritage-review-home')
    expect(home.at_css('section.review-card').text.squish).to include('0 verses due', 'Review complete')
    expect(home.at_css('.first-due')['href']).to eq(test_ref_path)
  end

  it 'shows two completed cards and zero progress for an empty collection' do
    sign_in FactoryBot.create(:user, confirmed_at: Time.current, translation: 'KJV')
    get '/'
    home = Nokogiri::HTML(response.body).at_css('.heritage-review-home')
    expect(home.css('a, progress')).to be_empty
    expect(home.css('.review-complete').length).to eq(2)
    expect(home.css('dd').map { |dd| dd.text.squish }).to eq(['0 days', '0 of 0'])
  end

  it 'renders the canvas blog browse, category, tag, and archive states' do
    author = FactoryBot.create(:user, admin: true)
    blog = Bloggity::Blog.create!(title: 'Memverse Blog', url_identifier: 'main')
    category = Bloggity::BlogCategory.create!(name: 'Memorization', blog: blog)
    post = Bloggity::BlogPost.create!(blog: blog, posted_by: author, title: 'Scripture practice', body: 'A&nbsp;lasting treasure. &lt;img src=x onerror=alert(1)&gt;', category: category, is_complete: true)
    allow(Bloggity::BlogPost).to receive(:search).and_return([post])
    get '/blog/blog_search', params: {search_param: 'Scripture'}
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Browse and search.', 'Scripture practice', 'heritage-blog-search')
    search_document = Nokogiri::HTML(response.body)
    expect(search_document.at_css('.one_blog p').text).to include("A\u00a0lasting treasure.")
    expect(search_document.css('.one_blog img')).to be_empty
    expect(search_document.at_css('.heritage-article-taxonomy').text).to include('Memorization')
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
