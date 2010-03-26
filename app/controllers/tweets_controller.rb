class TweetsController < ApplicationController
 
  def index
    @tweets = Tweet.all(:order => "created_at DESC")
    respond_to do |format|
      format.html
    end
  end

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

  def update
    @tweet = Tweet.first(:order => "created_at DESC")
    
#    render :xml => { :tweet => @tweet.news, :time => @tweet.created_at }.to_xml
#    render @tweet.news, :time => @tweet.created_at }.to_xml
    render :partial=>'tweet', :layout=>false
    
  end

end # Class
