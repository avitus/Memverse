module Bloggity
	module UrlHelper
		
		# Create a named url for the blog and action combination
		def blog_named_link(blog_post, the_action = :show, options = {})
			
			if blog_post
				case the_action
			    when :quest   then "#{DOMAIN_NAME}/blog/#{blog_post.blog.url_identifier}/#{blog_post.url_identifier}"   
					when :show    then "/blog/#{blog_post.blog.url_identifier}/#{blog_post.url_identifier}"
					when :list    then "/blog/#{blog_post.blog.url_identifier}/#{blog_post.url_identifier}?page=#{options[:page]}"
					when :index   then "/blog/#{options[:blog].url_identifier}"
					when :feed    then { :controller => 'blogs', :id => options[:blog].id, :action => :feed }
					else
						{ :controller => 'blog_posts', :action => the_action, :blog_id => (options[:blog] && options[:blog].id) || blog_post.blog_id, :id => blog_post }
				end
			else
			  "/blog"   # redirect to home page of blog on error		
			end
			
		end
		
	end
end