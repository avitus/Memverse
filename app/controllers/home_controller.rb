class HomeController < ApplicationController

  before_action :authenticate_user!, :except => :index

  def index
    redirect_to :controller => "memverses", :action => "index" and return if user_signed_in?

    if params[:referrer]
      session[:referrer] = User.find_by_login(params[:referrer]).id if User.find_by_login(params[:referrer])
    end

    # TODO: Caching these requests gives an error about a frozen object
    # @blogposts = Rails.cache.fetch(["latest_blog_posts"], :expires_in => 2.hours) do
      # BlogPost.where(:is_complete => true).order("created_at DESC").limit(2)
    # end
    @blogposts = Bloggity::BlogPost.where(:is_complete => true).order("created_at DESC").limit(2)


    # @vsillumination = Rails.cache.fetch(["pop_vs_illumination"], :expires_in => 24.hours) do
      # Popverse.order_by_rand.limit(10).all
    # end
    @vsillumination = Popverse.order_by_rand.limit(10)

    render :layout => false
  end

  def quick_start
    @hide_select = true # hide translation dropdown
  end

end
