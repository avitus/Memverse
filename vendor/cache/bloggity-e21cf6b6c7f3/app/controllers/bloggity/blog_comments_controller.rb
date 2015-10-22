module Bloggity
class BlogCommentsController < ApplicationController

  include Bloggity::ApplicationHelper

  before_filter :authenticate_user!
  before_filter :load_blog_comment, :only => [:approve, :destroy, :edit, :update]
  before_filter :blog_comment_moderator_or_redirect, :only => [:approve, :destroy]

  add_breadcrumb "Home", "/home"
  add_breadcrumb "Blog", "/blog"

  protect_from_forgery :except => [:create]

  # POST /blogs_comments
	# POST /blogs_comments.xml
	def create
		if current_user.can_comment? && params[:subject].empty?
			@blog_comment = BlogComment.new(params[:blog_comment])
			@blog_comment.user_id = current_user.id
			@blog_comment.save
			@blog_post = @blog_comment.blog_post
			redirect_to(blog_named_link(@blog_post))
		else
			flash[:error] = "You are not yet allowed to comment on blog posts"
			redirect_to(blog_named_link(@blog_post))
		end
	end

	def edit
    add_breadcrumb "Edit Comment", { :controller => 'blog_comments', :action => :edit, :id => @blog_comment.id }
	end

	def update
		@blog_comment.update_attributes(params[:blog_comment])
		redirect_to(blog_named_link(@blog_post))
	end

  def destroy
		@blog_comment.destroy
		redirect_to request.referrer
	end

	def approve
		flash[:notice] = "Comment was approved!"
		@blog_comment.update_attribute(:approved, true)
		redirect_to request.referrer
	end

  # Added by ALV
  def recent_comments
    @tab = "blog"
    @sub = "comments"
    add_breadcrumb I18n.t("blog_menu.Recent Comments"), "/blog_comments_new"

    @newest_comments = Rails.cache.fetch("recent_comments", :expires_in => 30.minutes) do
			# BlogComment.find_all_by_approved(true, :all, :limit => 40, :order => "created_at DESC")
      BlogComment.where(:approved => true).order("created_at DESC").limit(40)
		end
  end

	def load_blog_comment
		@blog_comment = BlogComment.find(params[:id])
		@blog_post = @blog_comment.try(:blog_post)
		@blog = @blog_post.try(:blog)
		@blog_id = @blog && @blog.id
		unless current_user && @blog_comment && ((current_user == @blog_comment.user) || (current_user.can_moderate_blog_comments?(@blog && @blog.id)))
			flash[:error] = "You don't have permission to edit that comment"
			redirect_to blog_named_link(@blog_post)
			false
		else
			true
		end
	end
end
end
