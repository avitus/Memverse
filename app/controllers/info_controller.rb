# coding: utf-8

class InfoController < ApplicationController
 
  def tutorial
    @tab = "learn"    
    @page_title = "Memverse : Overview" 
    # Check for quest completion
    spawn_block do
      q = Quest.find_by_url(url_for(:action => 'tutorial', :controller => 'info', :only_path => false))
      q.check_quest_off(current_user)
      flash.keep[:notice] = "You have completed the task: #{q.task}"
    end
  end
  
  def sm_description
    @tab = "learn"     
    @page_title = "The SuperMemo Algorithm" 
  end
  
  def volunteer
    @tab = "contact"     
    @page_title = "Volunteer" 
  end  

  # ----------------------------------------------------------------------------------------------------------   
  # Contact and Connect Page
  # ----------------------------------------------------------------------------------------------------------    
  def contact
    @tab = "contact"    
    @page_title = "Memverse : Contact / Feedback" 
  end  
 
  # ----------------------------------------------------------------------------------------------------------   
  # Contact and Connect Page
  # ----------------------------------------------------------------------------------------------------------    
  def faq
    @tab = "contact"    
    @page_title = "Memverse : Help & Support" 
  end    
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------   
  def pop_verses
    
    @page_title = "Memverse : Popular Verses"     
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

    @page_title = "Memverse : Popular Verses"     
    
    book = params[:search_param]
        
    @vs_list =  Verse.rank_verse_popularity(limit=9, book)
    
    render :partial => 'pop_verses', :layout=>false 
  end   
  
  
  # ----------------------------------------------------------------------------------------------------------   
  # Display a single verse
  # ---------------------------------------------------------------------------------------------------------- 
  def show_vs
    @page_title = "Memverse : Popular Verses" 
    @verse = Verse.find(params[:vs])
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def leaderboard
    
    @tab          = "leaderboard" 
    @page_title   = "Memverse Leaderboard"
    @leaderboard  = User.top_users  # returns top users sorted by number of verses memorized

    @not_on_leaderboard = (current_user.memorized < @leaderboard.last[1]) unless !current_user
  end

  # ----------------------------------------------------------------------------------------------------------
  # Church Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def churchboard
    
    @tab          = "leaderboard" 
    @page_title   = "Memverse Church Leaderboard"
    @churchboard  = Church.top_churches  # returns top users sorted by number of verses memorized

  end    

  # ----------------------------------------------------------------------------------------------------------
  # US States Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def stateboard
    
    @tab          = "leaderboard" 
    @page_title   = "Memverse US State Challenge"
    @stateboard   = AmericanState.top_states  # returns top states sorted by number of verses memorized

  end       
    
  # ----------------------------------------------------------------------------------------------------------
  # Country Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def countryboard
    
    @tab          = "leaderboard" 
    @page_title   = "Memverse Global Challenge"
    @countryboard  = Country.top_countries  # returns top users sorted by number of verses memorized

  end      

  # ----------------------------------------------------------------------------------------------------------   
  # Top referrers
  # ---------------------------------------------------------------------------------------------------------- 
  def referralboard
    @tab            = "leaderboard"
    @page_title     = "Referrals Leaderboard"
    @referralboard = User.top_referrers
    
    @not_on_referralboard = (current_user.num_referrals < @referralboard.last[1]) unless !current_user
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show some nice statistics
  # ----------------------------------------------------------------------------------------------------------   
  def memverse_clock
    @tab        = "leaderboard"    
    @page_title = "Memverse Global Chart"
    
    last_entry        = DailyStats.global.find(:first, :order => "entry_date DESC")
    
    @global_users     = last_entry.users_active_in_month
    @last_entry       = last_entry.entry_date
    @memorized_verses = last_entry.memverses_memorized
    
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # RSS News Feed
  # ---------------------------------------------------------------------------------------------------------- 
  def news
    @page_title = "Memverse News Network"
    @tab = "home"    
    
    # === RSS News feed ===
    # Poached from http://www.robbyonrails.com/articles/2005/05/11/parsing-a-rss-feed
    feed_url  = 'http://feeds.christianitytoday.com/christianitytoday/ctmag'
    feed_sec  = 'http://feeds.christianitytoday.com/christianitytoday/history'
    
    @posts    = RssReader.posts_for(feed_url, length=5, perform_validation=false)

    # === Check secondary feed if necessary
    if !@posts
      @posts   = RssReader.posts_for(feed_sec, length=5, perform_validation=false)
    end
  
    # Strip out links to Digg, StumbleUpon etc.
    if @posts
      @posts.each { |post| 
        post.description = post.description.split("<div")[0]
      }
    end
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Memorize
  # ----------------------------------------------------------------------------------------------------------   
  def demo_test_verse
 
    @page_title = "Demo Memory Verse Review"
     
    params[:verseguess] = ""  
    @verse            = "Romans 12:2"
    @text             = "Do not conform any longer to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God's will is — his good, pleasing and perfect will."
    @current_versenum = 2
    
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
