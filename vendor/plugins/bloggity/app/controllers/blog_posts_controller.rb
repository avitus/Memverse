class BlogPostsController < ApplicationController
  before_filter :get_bloggity_page_name, :except => :blog_search
  before_filter :load_blog_post, :except => :blog_search
  before_filter :blog_writer_or_redirect, :except => [:close, :index, :show, :feed, :blog_search]
	
  # GET /blog_posts
  # GET /blog_posts.xml
  add_breadcrumb "Home", "/home"
  add_breadcrumb "Blog", "/blog"
  def index
    
    @tab = "blog"
    @sub = "view"

		@blog_page = params[:page] || 1
	  @recent_posts = recent_posts(@blog_page)
		@blog_posts = if(params[:tag_name] || params[:category_id])
			# This is how I'd *like* to filter on tag/category:  
			#search_condition = { :blog_id => @blog_id, :is_complete => true }
			#search_condition.merge!(:blog_tags => { :name => params[:tag_name] }) if params[:tag_name]
			# However something about the interaction of these options is terminally dumb, as the include or join 
			# is ignored by the test suite or script/server, respectively, when using this logic.
			
			# So alas... we must hack away:
			search_condition = ["blog_id = ? AND is_complete = ? #{"AND blog_tags.name = ?" if params[:tag_name]} #{"AND category_id = ?" if params[:category_id]}", @blog_id, true, params[:tag_name], params[:category_id]].compact
      BlogPost.where(search_condition).select("DISTINCT blog_posts.*").includes(:tags).page(@blog_page).order("blog_posts.created_at DESC")      
		else
			logger.info("*** Showing recent posts ")
			@recent_posts
		end
			
		@page_name = @blog.title
	    
		respond_to do |format|
	      format.html # index.html.erb
	      format.xml  { render :xml => @blog_posts }
    end
  end
	
	def close
		@blog_post = BlogPost.find(params[:id])
    if blog_logged_in? && current_user.can_moderate_blog_comments?(@blog_id)
      @blog_post.update_attribute(:comments_closed, true)
      flash[:notice] = "Commenting for this blog has been closed."
    else
      flash[:notice] = "You do not have sufficient privileges to complete this action."
    end
    redirect_to blog_named_link(@blog_post)
	end

	# Upload a blog asset
	def create_asset
		image_params = params[:blog_asset] || {}
		@image = BlogAsset.new(image_params)
		@image.blog_post_id = image_params[:blog_post_id] # Can't mass-assign attributes of attachment_fu, so we'll set it manually here
		@image.save!
		render :text => @image.public_filename
	end
	
  # GET /blog_posts/1
  # GET /blog_posts/1.xml
  def show
    @tab = "blog"
    @blog_page = params[:page] || 1
    
    Rails.logger.info("*** Fetching recent posts for blog page #{@blog_page}")
    
    @recent_posts = recent_posts(@blog_page)
    
    @blog_post = BlogPost.where("id = ? OR url_identifier = ?", params[:id], params[:id]).first
    
    if !@blog_post || (!@blog_post.is_complete  && (!current_user || !current_user.can_blog?(@blog_post.blog_id)))
      @blog_post = nil
      flash[:error] = "You do not have permission to see that blog post."
      return (redirect_to( :action => 'index' ))
    else
	  @page_name = @blog_post.title
      add_breadcrumb @blog_post.title, blog_named_link(@blog_post)

      # Used to check off quests
      # spawn_block do
      if current_user && q = Quest.find_by_url( blog_named_link(@blog_post, :quest) )
        if current_user.quests.where(:id => q.id).empty?
          q.check_quest_off(current_user)
          flash.keep[:notice] = "You have completed the task: #{q.task}"
        end
      end
      # end        
      
    end
	
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @blog_post }
    end
  end

  # GET /blog_posts/new
  # GET /blog_posts/new.xml
  def new
    @tab = "blog"
    @blog_post = BlogPost.new(:posted_by => current_user, :fck_created => true, :blog_id => @blog_id)
		@blog_post.save # save it before we start editing it so we can know it's ID when it comes time to add images/assets
		redirect_to blog_named_link(@blog_post, :edit)
  end

  # GET /blog_posts/1/edit
  def edit
		@blog_post = BlogPost.find(params[:id])
  end

  # POST /blog_posts
  # POST /blog_posts.xml
  def create
    @tab = "blog"
    @blog_post = BlogPost.new(params[:blog_post])
    @blog_post.posted_by = current_user

    if(@blog_post.save)
      redirect_to blog_named_link(@blog_post)
    else
      render blog_named_link(@blog_post, :new)
    end
  end

  # PUT /blog_posts/1
  # PUT /blog_posts/1.xml
  def update
    @blog_post = BlogPost.find(params[:id])
    
    if @blog_post.update_attributes(params[:blog_post])
      redirect_to blog_named_link(@blog_post)
    else
      render blog_named_link(@blog_post, :edit)
    end
  end

  # DELETE /blog_posts/1
  # DELETE /blog_posts/1.xml
  def destroy
		@blog = @blog_post.blog
		@blog_post.destroy
    flash[:message] = "Blog #{@blog_post.title} was destroyed."
    redirect_to(blog_named_link(nil, :index, { :blog => @blog }))
  end
	
	def pending
    @tab = "blog" 
    blog_page = params[:page] || 1
		@pending_posts = BlogPost.paginate(:all, :conditions => ["blog_id = ? AND is_complete = ?", @blog_id, false], :order => "blog_posts.created_at DESC", :page => blog_page, :per_page => 15)
		@recent_posts = recent_posts(blog_page)
	end
	
	
  # ----------------------------------------------------------------------------------------------------------
  # Blog Search Results
  # ----------------------------------------------------------------------------------------------------------  	
	def blog_search_results	  
		@tab = "blog"
    @sub = "blogsearch"
    @blog_search_results = BlogPost.search( params[:search_param] )
    respond_to do |format| 
      format.html { render :partial => 'blog_search_results', :layout=>false }
      format.xml  { render :xml 	=> @blog_search_results }
    end	    
	end


  # ----------------------------------------------------------------------------------------------------------
  # Blog Search Query page
  # ---------------------------------------------------------------------------------------------------------- 	
	def blog_search
    @tab = "blog"
    @sub = "blogsearch"		
		@blog_search_results = Array.new
	  @blog_search_results = BlogPost.search( params[:search_param] || "memorize" )
	end

	# --------------------------------------------------------------------------------------
	# --------------------------------------------------------------------------------------
	private
	# --------------------------------------------------------------------------------------
	# --------------------------------------------------------------------------------------
	
	def load_blog_post
		load_blog
		@blog_post = BlogPost.find(:first, :conditions => ["blog_id = ? AND (id = ? OR url_identifier = ?)", @blog_id, params[:id], params[:id]]) if params[:id]
	end
	
	def recent_posts(blog_page)
		Rails.logger.debug("*** Loading recent posts for blog with id: #{@blog_id}")
    BlogPost.where(:blog_id => @blog_id, :is_complete => true).page(@blog_page).order("created_at DESC")
	end
end
