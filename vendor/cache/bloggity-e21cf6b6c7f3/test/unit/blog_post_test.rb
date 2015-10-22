require File.dirname(__FILE__) + '/../test_helper'

class BlogPostTest < ActiveSupport::TestCase
	
	# Test our validations for new blogs
	def test_create
		blog_post = get_fixture(BlogPost, "blog_post_valid_and_posted")
		assert blog_post.valid?
		
		blog_post.blog_id = nil
		assert !blog_post.valid?
		assert blog_post.errors.on(:blog_id)
		
		blog_post = get_fixture(BlogPost, "blog_post_valid_and_posted")
		user = get_fixture(User, "users_001")
		def user.can_blog?(blog_id = nil)
			false
		end
		blog_post.posted_by = user
		assert !blog_post.valid?
		assert blog_post.errors.on(:posted_by_id)
	end
	
	def test_url_identifier
		blog_post = get_fixture(BlogPost, "blog_post_valid_and_posted")
		blog_post.is_complete = false
		blog_post.title = "My first blog"
		blog_post.save
		assert_equal blog_post.url_identifier, "My_first_blog"
		
		blog_post.is_complete = true
		blog_post.title = "My second blog"
		blog_post.save
		assert_equal blog_post.url_identifier, "My_first_blog"
	end
	
	def test_tag_creation
		blog_post = get_fixture(BlogPost, "blog_post_valid_and_posted")
		blog_post.tag_string = "Pony, horsie, doggie"
		blog_post.save
		assert_equal blog_post.tags.size, 3
		
		blog_post.tag_string = "Parrot"
		blog_post.save
		assert_equal blog_post.tags.size, 1
	end

# Need to add the equivalent of these test

# describe BlogPost do

#   before(:each) do
#     @blog = FactoryGirl.create(:blog, :title => "Memverse Blog")
#     @user = FactoryGirl.create(:user, :id => 2) # user with id of 2 will be allowed to post
#   end

#   it "should give URL identifier" do
#     post = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
#     post.url_identifier.should == "scripture-memorization"
#   end

#   it "should not give the same URL identifier" do
#     post1 = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
#     post2 = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    
#     post1.url_identifier.should == "scripture-memorization"
#     post2.url_identifier.should == "scripture-memorization--1"
#   end
# end


end
