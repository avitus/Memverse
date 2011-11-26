class HomeController < ApplicationController
  
  def index
    redirect_to :controller => "memverses", :action => "index" and return if user_signed_in?
    session[:referrer] = params[:referrer]
     
    @blogposts = Rails.cache.fetch(["latest_blog_posts"], :expires_in => 2.hours) do 
      BlogPost.where(:is_complete => true).order("created_at DESC").limit(2)
    end
    
    @vsillumination = Rails.cache.fetch(["pop_vs_illumination"], :expires_in => 24.hours) do 
      Popverse.random(10)
    end
    
    render :layout => false
  end  
   
end
