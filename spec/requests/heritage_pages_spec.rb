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
    [manage_verses_path, add_verse_path, progress_path, update_profile_path, edit_user_registration_path, user_path(user), passage_review_path].each do |path|
      get path
      expect(response).to have_http_status(:ok), "#{path}: #{response.status}"
      expect(response.body).to include('mv-heritage')
      expect(response.body).not_to include('designs.magicpath.ai', 'Experimental - Use with Caution!')
      expect(response.body).to include('data-heritage-collection') if path == manage_verses_path
      expect(response.body).to include('heritage-progress') if path == progress_path
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

end
