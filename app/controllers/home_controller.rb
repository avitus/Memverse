class HomeController < ApplicationController
  
  def index
    redirect_to :controller => "memverses", :action => "index" and return if user_signed_in?
    session[:referrer] = params[:referrer]
    @blogposts = BlogPost.all(:limit => 2, :order => "created_at DESC", :conditions => ["is_complete = ?", true])
    @vsillumination = Popverse.find(:all, :order => "RAND()", :limit => 10)
    render :layout => false
  end  
   
end
