class TweetsController < ApplicationController
 
  # ----------------------------------------------------------------------------------------------------------
  # Show recent tweets
  # ----------------------------------------------------------------------------------------------------------  
  def index
    @tweets = Tweet.all(:limit => 100, :order => "created_at DESC")
    respond_to do |format|
      format.html
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Create a new tweet
  # ----------------------------------------------------------------------------------------------------------   
  def create
    @tweet = Tweet.create(:message => params[:message])
    respond_to do |format|
      if @tweet.save
        format.html { redirect_to posts_path }
      else
        flash[:notice] = "Tweet failed to save."
        format.html { redirect_to tweets_path }
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Get the lastest news event that exceeds a certain importance level
  # ----------------------------------------------------------------------------------------------------------   
  def update
    
    importance = params[:importance].to_i || 5
    
    # Handles case where importance is not specified
    if importance == 0
      importance = 5
    end
    
    logger.info("Checking for tweets more important than #{importance}")
    
    @tweet = Tweet.first(:order => "created_at DESC", :conditions => ["importance <= ?", importance])
    
    render :partial=> 'tweets/tweet', :locals => { :tweet => @tweet }, :layout=>false
    
  end 

end # Class
