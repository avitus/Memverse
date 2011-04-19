# coding: utf-8

class InfoController < ApplicationController
 
  # ----------------------------------------------------------------------------------------------------------   
  # Memverse tutorial
  # ---------------------------------------------------------------------------------------------------------- 
  def tutorial
    @tab = "learn" 
    @sub = "tutorial"   
    # Check for quest completion
    spawn_block do
      q = Quest.find_by_url(url_for(:action => 'tutorial', :controller => 'info', :only_path => false))
      if q
		    q.check_quest_off(current_user)
		    flash.keep[:notice] = "You have completed the task: #{q.task}"
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------   
  # Supermemo Algorithm
  # ----------------------------------------------------------------------------------------------------------   
  def sm_description
    @tab = "learn" 
    @sub = "smalg"   
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Video Tutorial
  # ----------------------------------------------------------------------------------------------------------   
  def video_tut
  	@tab = "learn"
  	@sub = "vidtut"
  end

  # ----------------------------------------------------------------------------------------------------------   
  # Volunteer Info
  # ----------------------------------------------------------------------------------------------------------   
  def volunteer
    @tab = "contact"     
    @sub = "volunteer"     
  end  

  # ----------------------------------------------------------------------------------------------------------   
  # Contact and Connect Page
  # ----------------------------------------------------------------------------------------------------------    
  def contact
    @tab = "contact" 
    @sub = "contact"        
  end  
 
  # ----------------------------------------------------------------------------------------------------------   
  # FAQ / Help
  # ----------------------------------------------------------------------------------------------------------    
  def faq
    @tab = "contact"  
    @sub = "help"        
  end    
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------   
  def pop_verses
    
    @page       = params[:page].to_i    # page number
    @page_size  = 10                    # number of verses per page
       
    @vs_list = Popverse.find( :all, :limit => @page_size, :offset => @page*@page_size )    
  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Interactive Database Filter
  # Inputs:   
  # Outputs:  
  # ----------------------------------------------------------------------------------------------------------  
  def pop_verses_by_book
    @vs_list = Array.new
  end
  
  
  def pop_verse_search
   
    book = params[:search_param]
        
    @vs_list =  Verse.rank_verse_popularity(limit=9, book)
    
    render :partial => 'pop_verses', :layout=>false 
  end   
  
  
  # ----------------------------------------------------------------------------------------------------------   
  # Display a single verse
  # ---------------------------------------------------------------------------------------------------------- 
  def show_vs
    @verse = Verse.find(params[:vs])
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def leaderboard
    
    @tab          = "leaderboard" 
    @sub 		  = "solo"
    @leaderboard  = User.top_users  # returns top users sorted by number of verses memorized

    @not_on_leaderboard = (current_user.memorized < @leaderboard.last[1]) unless !current_user
  end

  # ----------------------------------------------------------------------------------------------------------
  # Church Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def churchboard
    
    @tab          = "leaderboard" 
    @sub 		  = "church"
    
    @churchboard  = Church.top_churches  # returns top users sorted by number of verses memorized

  end    

  # ----------------------------------------------------------------------------------------------------------
  # US States Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def stateboard
    
    @tab          = "leaderboard" 
    @sub 		  = "us-state"
    
    @stateboard   = AmericanState.top_states  # returns top states sorted by number of verses memorized

  end       
    
  # ----------------------------------------------------------------------------------------------------------
  # Country Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def countryboard
    
    @tab          = "leaderboard" 
    @sub 		  = "country"
    
    @countryboard  = Country.top_countries  # returns top users sorted by number of verses memorized

  end      

  # ----------------------------------------------------------------------------------------------------------   
  # Top referrers
  # ---------------------------------------------------------------------------------------------------------- 
  def referralboard
    @tab          = "leaderboard"
    @sub 		  = "referrals"
    
    @referralboard = User.top_referrers
    
    @not_on_referralboard = (current_user.num_referrals < @referralboard.last[1]) unless !current_user
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show some nice statistics
  # ----------------------------------------------------------------------------------------------------------   
  def memverse_clock
    @tab          = "leaderboard" 
    @sub 		  = "global"
       
   
    last_entry        = DailyStats.global.find(:first, :order => "entry_date DESC")
    
    @global_users     = last_entry.users_active_in_month
    @last_entry       = last_entry.entry_date
    @memorized_verses = last_entry.memverses_memorized
    
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # RSS News Feed
  # ---------------------------------------------------------------------------------------------------------- 
  def news
    @tab = "home" 
    @sub = "news"   
    
    feed_urls	= Array.new
    @feeds 		= Array.new
    
    # === RSS News feed ===
    # Poached from http://www.robbyonrails.com/articles/2005/05/11/parsing-a-rss-feed
    feed_urls << 'http://feeds.christianitytoday.com/christianitytoday/ctmag'
    feed_urls << 'http://feeds.christianitytoday.com/christianitytoday/history'
    feed_urls << 'http://www.christianpost.com/services/rss/feed/most-popular'
    feed_urls << 'http://rss.feedsportal.com/c/32752/f/517092/index.rss'
        
    feed_urls.each { |fd_url|
	  @feeds[ feed_urls.index(fd_url) ]  = RssReader.posts_for(fd_url, length=5, perform_validation=false)
    }
    
    @feeds.each { |feed|
      if feed
        feed.each { |post| 
          # Strip out links to Digg, StumbleUpon etc.
          post.description = post.description.split("<div")[0].split("<img")[0]
        }      	
      end	
    } 
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Memorize
  # ----------------------------------------------------------------------------------------------------------   
  def demo_test_verse
     
    params[:verseguess] = ""  
    @verse            = "Rom 12:2"
    @text             = "Do not conform any longer to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God's will is — his good, pleasing and perfect will."
    @current_versenum = 2
    @mnemonic         = "D n c a l t t p o t w, b b t b t r o y m. T y w b a t t a a w G w i - h g, p a p w."
    @prior_text       = "Therefore, I urge you, brothers, in view of God's mercy, to offer your bodies as living sacrifices, holy and pleasing to God — this is your spiritual act of worship."
    @prior_versenum   = 1
end

  # ----------------------------------------------------------------------------------------------------------
  # Check for errors in verse test
  # Note: we should remove the 'strip' and whitespace substitution 
  #       on the correct verse once we're sure that all the old verses have been
  #       correctly stripped. Newer verses are stripped when saved
  # ----------------------------------------------------------------------------------------------------------  
  def feedback
    
    
    guess   = params[:verseguess] ? params[:verseguess].gsub(/\s+/," ").strip : ""  # Remove double spaces from guesses    
    correct = params[:correct]    ? params[:correct].gsub(/\s+/," ").strip    : ""  # The correct verse was stripped, cleaned when first saved    
        
      @correct  = correct
      @feedback = ""  # find a better way to construct the string
 
      guess_words = guess.split
      right_words = correct.split  
      
      if !right_words.empty?
          
        guess_words.each_index { |i|
          if i < right_words.length # check that guess isn't longer than correct answer
            if guess_words[i].downcase.gsub(/[^a-z ]/, '') == right_words[i].downcase.gsub(/[^a-z ]/, '')
              @feedback = @feedback + right_words[i] + " "  
            else
              @feedback = @feedback + "..."
            end
          end          
        }
        
        # Check for complete match       
        @match = (  guess.downcase.gsub(/[^a-z ]/, '') == correct.downcase.gsub(/[^a-z ]/, '')  )
 
      end

    render :partial=>'feedback', :layout=>false
    
  end 
  
end
