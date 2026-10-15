require 'rails_helper'

# The Bloggity engine (mounted at /blog) ships admin templates that call
# FormBuilder#error_messages, which was removed in Rails 3 (Sentry MEMVERSE-9G),
# and a BlogsController with no authorization filter. These specs cover the
# app-side overrides in app/views/bloggity and config/initializers/bloggity_decorator.rb.
RSpec.describe "Bloggity admin pages", type: :request do
  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:user)  { FactoryBot.create(:user) }
  let!(:blog) { Bloggity::Blog.create!(title: "Memverse Blog", subtitle: "News and updates") }

  describe "blog settings" do
    context "as an admin" do
      before { sign_in admin }

      it "renders the edit page" do
        get "/blog/blogs/#{blog.id}/edit"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Editing Blog")
        expect(response.body).to include('value="Memverse Blog"')
      end

      it "submits the edit form to the engine's blog URL" do
        get "/blog/blogs/#{blog.id}/edit"

        expect(response.body).to include(%(action="/blog/blogs/#{blog.id}"))
      end

      it "shows validation errors when an update is invalid" do
        patch "/blog/blogs/#{blog.id}", params: { blog: { title: "" } }

        expect(response.body).to include("Title can&#39;t be blank")
        expect(blog.reload.title).to eq("Memverse Blog")
      end

      it "saves a valid update" do
        patch "/blog/blogs/#{blog.id}", params: { blog: { title: "Memverse News" } }

        expect(blog.reload.title).to eq("Memverse News")
      end
    end

    context "as a signed-in non-admin" do
      before { sign_in user }

      it "redirects away from the edit page" do
        get "/blog/blogs/#{blog.id}/edit"

        expect(response).to redirect_to("/blog")
      end

      it "cannot update a blog" do
        patch "/blog/blogs/#{blog.id}", params: { blog: { title: "Hijacked" } }

        expect(response).to redirect_to("/blog")
        expect(blog.reload.title).to eq("Memverse Blog")
      end
    end

    context "as an anonymous visitor" do
      it "redirects away from the edit page" do
        get "/blog/blogs/#{blog.id}/edit"

        expect(response).to redirect_to("/blog")
      end

      it "cannot destroy a blog" do
        expect { delete "/blog/blogs/#{blog.id}" }.not_to change(Bloggity::Blog, :count)
        expect(response).to redirect_to("/blog")
      end

      it "cannot create a blog" do
        expect { post "/blog/blogs", params: { blog: { title: "Spam Blog" } } }
          .not_to change(Bloggity::Blog, :count)
        expect(response).to redirect_to("/blog")
      end

      it "can still read the blog feed" do
        get "/blog/blogs/#{blog.id}/feed"

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/xml")
      end
    end
  end

  describe "blog category settings" do
    let!(:category) { Bloggity::BlogCategory.create!(name: "Announcements", blog: blog) }

    context "as an admin" do
      before { sign_in admin }

      it "renders the edit page" do
        get "/blog/blog_categories/#{category.id}/edit"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('value="Announcements"')
      end

      it "shows validation errors when an update is invalid" do
        patch "/blog/blog_categories/#{category.id}", params: { blog_category: { name: "" } }

        expect(response.body).to include("Name can&#39;t be blank")
        expect(category.reload.name).to eq("Announcements")
      end
    end

    context "as a signed-in non-admin" do
      before { sign_in user }

      it "redirects away from the edit page" do
        get "/blog/blog_categories/#{category.id}/edit"

        expect(response).to redirect_to("/blog")
      end
    end
  end
end
