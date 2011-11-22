class BlogsController < ApplicationController
#  before_filter :get_bloggity_page_name
#	before_filter :can_modify_blogs_or_redirect, :except => [:feed, :show]
#	before_filter :load_blog, :only => [:feed, :show]
	add_breadcrumb "Home", "/home"
  
  def index
    @tab = "blog"
    @blogs = Blog.all
   
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blogs }
    end
  end

  def show
    @tab = "blog"
		if @blog
			redirect_to "/blog/#{@blog.url_identifier || @blog.id}"
		else
			redirect_to "/blog"
		end    
  end

  def new
    @blog = Blog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @blog }
    end
  end

  def edit
    @tab = "blog"
    @blog = Blog.find(params[:id])
  end

  def create
    @blog = Blog.new(params[:blog])

    respond_to do |format|
      if @blog.save
        flash[:notice] = 'Blog was successfully created.'
        format.html { redirect_to('/blogs/' + @blog.id.to_s)}
        format.xml  { render :xml => @blog, :status => :created, :location => @blog }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @blog = Blog.find(params[:id])

    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        flash[:notice] = 'Blog was successfully updated.'
        format.html { redirect_to('/blogs/' + @blog.id.to_s) }
        format.xml  { head :ok }
      else
        flash[:notice] = 'Blog was not updated.'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @blog = Blog.find(params[:id])
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to(blogs_url) }
      format.xml  { head :ok }
    end
  end
	
  # GET the blog as a feed
	def feed
	  
	  request.format = "xml" unless params[:format]
	  
		@blog = Blog.find(:first, :conditions => ["url_identifier = ? OR id = ?", params[:id], params[:id]])
		unless @blog
			flash[:error] = "Couldn't find that feed."
			redirect_to(:controller => 'blog_posts', action => :index)
			return
		end
		@blog_id = @blog.id
		@blog_posts = BlogPost.find(:all, :conditions => ["blog_id = ? AND is_complete = ?", @blog_id, true], :order => "blog_posts.created_at DESC", :limit => 15)
    respond_to do |format|
      format.xml
    end
	end
	
	private 
	
end
