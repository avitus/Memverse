module Bloggity
  module ApplicationHelper
  	
  	include PageNamesHelper
  	include UrlHelper

	def blog_logged_in?
		current_user && current_user.user_signed_in?
	end
	
	def load_blog
    	blog_id = params[:blog_id] || (params[:controller] == 'blogs' && params[:id]) # A little help for trying to access a blog from '/blogs/:id'
		if(blog_id.blank? && (blog_url_identifier = params[:blog_url_id_or_id]))
			@blog = Blog.find_by_url_identifier(blog_url_identifier)
		end

		# There is a default BlogSet created when the DB is bootstrapped, so we know we'll be able to fall back on this
		# We're using id=9 for now since this is the ID of the Memverse blog. Yes, ugliness abounds.
		@blog_id = blog_id || (@blog && @blog.id) || blog_url_identifier || 9 
		@blog = Blog.find(@blog_id) unless @blog
	end
	
	def blog_writer_or_redirect
		if @blog_id && current_user && current_user.can_blog?(@blog_id)
			true
		else
			flash[:error] = "You don't have permission to do that."
			redirect_to "/blog"
	      false
		end
	end
	
	def blog_comment_moderator_or_redirect
		if @blog_id && current_user && current_user.can_moderate_blog_comments?(@blog_id)
			true
		else
			flash[:error] = "You don't have permission to do that."
			redirect_to "/blog"
			false
		end
	end
	
	def can_modify_blogs_or_redirect
		if(current_user && current_user.can_modify_blogs?)
			true
		else
			redirect_to "/blog"
			false
		end
	end

	# ----------------------------------------------------------------------------------------------------------             
    # SEO Goodness
    #----------------------------------------------------------------------------------------------------------   
    def page_title(title = nil)
      if title
        content_for(:page_title) { title + " - Memverse" }
      else
        content_for?(:page_title) ? content_for(:page_title) : "Memverse"
      end
    end

  	
  end
end
