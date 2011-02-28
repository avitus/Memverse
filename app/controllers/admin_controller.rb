# coding: utf-8

class AdminController < ApplicationController

  protect_from_forgery  :except => [:set_verse_text, :verify_verse] 
  in_place_edit_for     :verse, :text  
  before_filter :authorize, :except => [:dashboard, :send_reminder ]

  
  # Only needed for scraping last verse data from BibleGateway
  #  require 'open-uri'
  #  require 'nokogiri'
  
  # ----------------------------------------------------------------------------------------------------------
  # Admin Dashboard
  # ----------------------------------------------------------------------------------------------------------   
  def dashboard
    
    @active_users_this_week = 0
    @active_users_today     = 0
    
    # Weekly Activity
    one_week_ago = Date.today-7
    
    @new_users_this_week    = User.count(     :all,  :conditions => ["created_at > ?", one_week_ago]) 
    @new_verses_this_week   = Verse.count(    :all,  :conditions => ["created_at > ?", one_week_ago])
    @new_mvs_this_week      = Memverse.count( :all,  :conditions => ["created_at > ?", one_week_ago])
    @active_users_this_week = User.active_this_week.count
    # Daily Activity   
    today = Date.today
    
    @new_users_today    = User.count(     :all,  :conditions => ["created_at > ?", today]) 
    @new_verses_today   = Verse.count(    :all,  :conditions => ["created_at > ?", today]) 
    @new_mvs_today      = Memverse.count( :all,  :conditions => ["created_at > ?", today])     
    @active_users_today = User.active_today.count
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show recent tweets
  # ----------------------------------------------------------------------------------------------------------  
  def tweets
    @tweets = Tweet.all(:limit => 100, :order => "created_at DESC")
    respond_to do |format|
      format.html
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Create a new tweet
  # ----------------------------------------------------------------------------------------------------------   
  def destroy_tweet
    @tweet = Tweet.find(params[:id])
    @tweet.destroy
    redirect_to :action => 'tweets' 
  end 

  # ----------------------------------------------------------------------------------------------------------
  # Verses per User
  # ----------------------------------------------------------------------------------------------------------   
  def verses_per_user
    
    # Memory Verses Per User
    @usage_table  = Hash.new(0)    
    @table_keys   = ["Pending", "0", "1-5", "6-10",  "11-20", "21-50", ">50"]
      
    # TODO: this table should be created using some fancy named scopes
    User.find(:all).each { |u| 
      if u.state=="pending"
        @usage_table["Pending"] += 1
      else
        @usage_table[quantize_mvs(u.memverses.count)] += 1
      end
    }     
    
    @num_users = User.count
  end


  # ----------------------------------------------------------------------------------------------------------
  # Verses per User
  # ----------------------------------------------------------------------------------------------------------   
  def get_last_verse_data
  
  require 'nokogiri'

  completed = []
  
  biblebooks = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
                '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
                'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 
                'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
                'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
                'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
                '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']     
    
 
    logger.info("===== Updating final verses table ====")
    # Delete previous table
    FinalVerse.delete_all     
    
    
    biblebooks.each { |bk|
    
      sleep(1)
    
      book = bk.downcase.gsub(" ","")
      logger.debug("Requesting URL for #{book}")
      
      url = 'http://www.deafmissions.com/tally/' + CGI.escape(book) + '.html'
      doc = Nokogiri::HTML(open(url))
      
      ch_vs_array = doc.at_css("tr").to_s.gsub(/<\/?[^>]*>/, "").split    

      # Need this from Daniel onwards
      if ch_vs_array.empty?
        ch_vs_array = doc.at_css("blockquote center").to_s.gsub(/<\/?[^>]*>/, "").split  
      end
      
      ch_vs_array.each { |cv| 
        
        ch, vs = cv.split(':')
        
        if ch.to_i == 0
          ch = CGI.escape(ch).gsub("%C2%A0","").to_i  # handle nbsp characters in a few chapters in Psalms
        end
        
        FinalVerse.create(:book => bk, :chapter => ch.to_i, :last_verse => vs.to_i )
        
      }
    
    }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Cohort Analysis
  # ----------------------------------------------------------------------------------------------------------   
  def cohort_analysis
    # Cohort analysis for users who added at least one verse
    
    @cohort_table   = Hash.new(0) # users who signed up in a given month
    @activity_table = Hash.new(0) # users who were active in past month
   
    # Cohort analysis     
    User.all.each { |u|
      if u.state=="active" and u.has_started?
        # Churn rate and cohort analysis
        @cohort_table[ date_label(u.created_at) ] += 1
        if Date.today - u.last_activity_date <= 30
          @activity_table[ date_label(u.created_at) ] += 1
        end        
      end
    }
  end
  

  # ----------------------------------------------------------------------------------------------------------
  # Convert date to month label
  # Input: 3/16/09
  # Output: 2009 03
  # ----------------------------------------------------------------------------------------------------------
  def date_label(date)
    month = date.month < 10 ? "0"+date.month.to_s : date.month.to_s
    year  = date.year.to_s
    
    return year + "-" + month
  end


  # ----------------------------------------------------------------------------------------------------------
  # Quantize Memory Verse per User
  # ----------------------------------------------------------------------------------------------------------
  def quantize_mvs(num_verses)
    return case num_verses
      when   0     then   "0"
      when   1..5  then   "1-5"
      when   6..10 then   "6-10"
      when  11..20 then   "11-20"
      when  21..50 then   "21-50"
      else                ">50"
    end
  end


  # ----------------------------------------------------------------------------------------------------------
  # Update table of popular verses
  # 
  # Returns data structure as follows:
  #  [Verse0, [translation_0, id_0], [translation_1, id_1]]
  #  [Verse1, [tranalation_0, id_0]
  #  etc.
  # Popular verses accesses the following DB tables:
  #   - Verse
  #   - Memory_Verse
  #   - User
  # ---------------------------------------------------------------------------------------------------------- 
  def update_popular_verses(limit = 25, include_current_user_verses = true)

    logger.info("===== Updating popular verses table ====")

    # Delete previous table
    Popverse.delete_all    

    # Changing the number of verses returned doesn't buy anything because you have to access entire memory verse table
    pop_mv = Verse.rank_verse_popularity(100) 
    
    pop_mv.each { |x|
    
      pv = Popverse.new
    
      pv.pop_ref    = x[0]
      pv.num_users  = x[1]
      errorcode, pv.book, pv.chapter, pv.versenum = parse_verse(pv.pop_ref)
          
    
      avail_translations = Verse.find( :all, 
                                       :conditions => ["book = ? and chapter = ? and versenum = ?", 
                                                        pv.book, pv.chapter, pv.versenum])              
          
      avail_translations.each { |vs|
      
        case vs.translation 
          when "NIV" then pv.niv = vs.id
          when "ESV" then pv.esv = vs.id
          when "NAS" then pv.nas = vs.id
          when "NKJ" then pv.nkj = vs.id
          when "KJV" then pv.kjv = vs.id
          when "RSV" then pv.rsv = vs.id        
        end    

        case vs.translation 
          when "NIV" then pv.niv_text = vs.text
          when "ESV" then pv.esv_text = vs.text
          when "NAS" then pv.nas_text = vs.text
          when "NKJ" then pv.nkj_text = vs.text
          when "KJV" then pv.kjv_text = vs.text
          when "RSV" then pv.rsv_text = vs.text      
        end 
      }
    
      pv.save

    }
    
    redirect_to :action => 'show_popverses'     
  end
    

  # ----------------------------------------------------------------------------------------------------------
  # Mass Email
  # ----------------------------------------------------------------------------------------------------------   
  def mass_email
    # Send out an email
    UserMailer.encourage_new_user_email(current_user).deliver
    redirect_to :action => 'leaderboard' 
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Send Newsletter
  # ----------------------------------------------------------------------------------------------------------   
  def send_newsletter
    
    start_with_user = 1
    
    # Send out an email
    recipients = User.find(:all, :conditions => ["id >= ?", start_with_user])
    logger.info("*** Sending newsletter to #{recipients.length} users")
    recipients.each { |r|
      if r.id >= start_with_user
        UserMailer.newsletter_email(r).deliver
      end
    }
    redirect_to :action => 'leaderboard' 
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Send Reminder Emails - sent out nightly at midnight
  # ----------------------------------------------------------------------------------------------------------   
  def send_reminder
  
    @emails_sent        = 0
    @email_list         = Array.new
    @reactivation_list  = Array.new  
    @encourage_list     = Array.new
    @bounce_list        = Array.new
      
    spawn_block do  
      # Retrieve records for all users  
      User.find(:all).each { |r|
        # Change reminder frequency (if necessary) to not be annoying
        r.update_reminder_freq
        
        if r.reminder_freq != "Never" and @emails_sent < 90
          
          # ==== Users who have added verses but are behind on memorizing ====
          if r.needs_reminder?
            if r.email.nil?
              logger.info("** Error: Unable to email user with id: #{r.id}")
              @bounce_list << r
            else
              if r.is_inactive?             
                # Reminder for inactive users
                logger.info("* Sending reminder email to #{r.login} - they've been inactive for two months")
                UserMailer.reminder_email_for_inactive(r).deliver             
              else 
                # Standard reminder email
                logger.info("* Sending reminder email to #{r.login}")
                UserMailer.reminder_email(r).deliver          
              end
              @emails_sent += 1
              r.last_reminder = Date.today
              r.save
              @email_list << r
            end
          end
          
          # ==== Users who never activated their accounts ====
          # ==== Send a second activation email and then delete the account after three days =====
          if r.never_activated?
            if r.created_at < 3.days.ago
              r.delete_account
            elsif r.last_reminder
              # do nothing - they've already received a second activation email
            else
              # logger.info("*** Resending activation email to #{r.login}")
              # UserMailer.signup_notification(r).deliver
              # @emails_sent += 1
              # r.last_reminder = Date.today
              # r.save
              # @reactivation_list << r
            end
          end
          
          # ==== Users who have activated but haven't ever added a verse ====
          if r.needs_kick_in_pants?    
            if r.email.nil?
              logger.info("** Error: Unable to email user with id: #{r.id}")
              @bounce_list << r
            else
              logger.info("* Sending kick in the pants to #{r.login}")
              UserMailer.encourage_new_user_email(r).deliver
              @emails_sent += 1
              r.last_reminder = Date.today
              r.save
              @encourage_list << r          
            end
          end
          
        end # block for users who want reminders
              
      }
      logger.info(" *** Sent #{@emails_sent} reminder emails")
    end # of spawn process
  end  


  # ----------------------------------------------------------------------------------------------------------
  # Show unapproved blog comments
  # ----------------------------------------------------------------------------------------------------------   
  def unapproved_comments
    @comments         = BlogComment.find_all_by_approved(false)
    @newest_comments  = BlogComment.find_all_by_approved(true, :all, :limit => 50, :order => "updated_at DESC")
    # TODO - figure out what to do with comments from deleted blog posts
  end
    
  # ----------------------------------------------------------------------------------------------------------
  # Remove dormant accounts and memory verses that haven't been started
  # TODO: This method is not currently being used
  # ----------------------------------------------------------------------------------------------------------   
  def housecleaning
    # Delete accounts of users with a) no verses and b) no activity for three months
    User.delete_users_who_never_got_started
    # Delete memory verses which have never been started and are a year old
    Memverse.delete_unstarted_memory_verses
    # Delete user accounts which have been inactive for two years
  end
      
  def mv_stats
    # TODO: Save statistics on deleted memory verses
    @never_started  = Memverse.never_started  # No attempts ever
    @abandoned      = Memverse.abandoned      # No attempts in 3 months
    @learning       = Memverse.learning       # Attempt in last three months but not yet memorized
    @memorized      = Memverse.memorized      # Memorized
  end
    
  # ----------------------------------------------------------------------------------------------------------
  # Send Reminder Emails
  # ----------------------------------------------------------------------------------------------------------   
  def send_reminder_test
    
    # Retrieve records for all users
    recipient = User.find(2) # This is me

    UserMailer.reminder_email(recipient).deliver

    redirect_to :action => 'show_verses' 
  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Leaderboard
  # ----------------------------------------------------------------------------------------------------------  
  def leaderboard
    
    @page_title = "Memverse Leaderboard"
    @leaderboard = User.top_users(200)  # returns top users sorted by number of verses memorized

    # TODO: move this somewhere else
    DailyStats.update()

  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Show all verses
  # ----------------------------------------------------------------------------------------------------------   
  def show_verses
    @vs_list = Verse.find(:all, :order => params[:sort_order])    
  end
    
  # ----------------------------------------------------------------------------------------------------------
  # Show verses that need verification ie. more than one user and have never been modified
  # ----------------------------------------------------------------------------------------------------------   
  def show_verses_to_be_checked
    @need_verification  = Array.new
    
    @error_reported   = Verse.find(:all, :conditions => {:error_flag => true })
    
    unverified_verses = Verse.find(:all, :conditions => {:verified => 'False'})
    unverified_verses.each { |vs| 
      # verse is unverified and has multiple users (ESV doesn't require checking, AFR will be checked by someone else
      if vs.memverses.count > 1 and vs.translation != "AFR"
        @need_verification << vs
      end
    }
    
    # If there are no unverified verses with more than one user then work on the rest
    if @need_verification.length == 0
      unverified_verses.each { |vs|
        if vs.translation != "AFR"
          @need_verification << vs
        end  
      }
    end

  end    
    
  # ----------------------------------------------------------------------------------------------------------
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------   
  def show_popverses
    @vs_list = Popverse.find(:all)    
  end    
    
    
  # ----------------------------------------------------------------------------------------------------------
  # Edit a verse
  # ----------------------------------------------------------------------------------------------------------   
  def edit_verse
    @verse = Verse.find(params[:id])    
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Edit a verse
  # ----------------------------------------------------------------------------------------------------------   
  def edit_church
    @church = Church.find(params[:id])    
  end    
  
  # ----------------------------------------------------------------------------------------------------------
  # Interactive Database Filter
  # Inputs:   
  # Outputs:  
  # ----------------------------------------------------------------------------------------------------------  
  def search_verses
    @vs_list = Array.new  
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Interactive Database Filter
  # Inputs:   
  # Outputs:  
  # ----------------------------------------------------------------------------------------------------------  
  def search_verse
    
    book         = params[:book]
    chapter      = params[:chapter]
    verse        = params[:verse]
    translation  = params[:translation]   
    
    @vs_list = Verse.find(:all, :conditions => {:book => book, :chapter => chapter, :versenum => verse, :translation => translation}, :limit => 24)
#    @vs_list = Verse.find(:all, :conditions => ["book = ? and chapter = ? and versenum = ? and translation = ?", book, chapter, verse, translation], :limit => 24)
    
    render :partial => 'search_verse', :layout=>false 
  end    

  # ----------------------------------------------------------------------------------------------------------
  # Interactive Database Filter
  # Inputs:   
  # Outputs:  
  # ----------------------------------------------------------------------------------------------------------  
  def search_users
    @user_list = Array.new  
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Interactive Database Filter
  # Inputs:   
  # Outputs:  
  # ----------------------------------------------------------------------------------------------------------  
  def search_user
    
    search_param = params[:search_param]
    
    # TODO: Is there a better way to do this search?
    
    @user_list =  User.find(:all, :conditions => {:login => search_param }, :limit => 5)
    
    if @user_list.empty?
      @user_list = User.find(:all, :conditions => {:email => search_param }, :limit => 5)
    end
  
    if @user_list.empty?
      @user_list = User.find(:all, :conditions => {:name  => search_param }, :limit => 5)
    end 
    
    render :partial => 'search_user', :layout=>false 
  end      
  
  # ----------------------------------------------------------------------------------------------------------
  # Show comprehensive data for a user
  # ----------------------------------------------------------------------------------------------------------   
  def show_user_info
    @user = User.find(params[:id])
    
    @mv_list = Memverse.find(:all, :conditions => ["user_id = ?", @user.id]).sort!
    
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Update a verse
  # ----------------------------------------------------------------------------------------------------------   
  def update_church
    @church = Church.find(params[:id])
    if @church.update_attributes(params[:church])
      flash[:notice] = "Church successfully updated"
      redirect_to :action => 'show_churches'
    else
      render :action => edit_church
    end
  end   
  
  def show_tags
    @tags = Tag.all
  end
  
  def show_verses_with_tag
    
    @mv_list = Array.new 
    @vs_list = Array.new
    
    @tag = Tag.find(params[:id])
    @tagged_items = @tag.taggings
    
    @tagged_items.each { |tagging|
      case tagging.taggable_type
        when "Memverse" then @mv_list << Memverse.find(tagging.taggable_id)
        when "Verse"    then @vs_list << Verse.find(tagging.taggable_id)
        else logger.info("*** Unknown object type has been tagged. This is bad") 
      end
    }
    
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # In place editing support
  # ----------------------------------------------------------------------------------------------------------    
  def set_verse_text
    @verse = Verse.find(params[:id])
    new_text = params[:value] # need to clean this up with hpricot or equivalent
    @verse.text = new_text
    @verse.save
    render :text => @verse.text
  end  
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Verify a verse
  # ----------------------------------------------------------------------------------------------------------  
  def verify_verse
    @verse = Verse.find(params[:id])
    @verse.verified   = true
    @verse.error_flag = false
    @verse.save
    render :text => "Verified"
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Update a verse TODO: Add automatic verification if the admin edits a verse
  # TODO: Check for duplicate verses
  # ----------------------------------------------------------------------------------------------------------   
  def update_verse
    @verse = Verse.find(params[:id])
    if @verse.update_attributes(params[:verse])
      flash[:notice] = "Verse successfully updated"
      redirect_to :action => 'search_verses'
    else
      render :action => edit_verse
    end
  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Delete a verse (this probably shouldn't ever be required)
  # ----------------------------------------------------------------------------------------------------------   
  def destroy_verse
    Verse.find(params[:id]).destroy
    
    # TODO: need to remove related memory verses !!!!!
    redirect_to :action => 'search_verses'
  end     

  # ----------------------------------------------------------------------------------------------------------
  # Check for duplicate verses
  # ----------------------------------------------------------------------------------------------------------    
  def users_with_problems
    @users = Memverse.check_for_duplicates
    logger.debug("Users with duplicate verses: #{@users.size}")
  end

  # ----------------------------------------------------------------------------------------------------------
  # Repair broken memory links for user
  # ----------------------------------------------------------------------------------------------------------   
  def fix_verse_linkage
    if params[:id]
      @report = User.find(params[:id]).fix_verse_linkage(repair = true)
    else
      flash[:notice] = "No user selected"
      redirect_to :action => 'search_users'
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show all memory verses for all users
  # ----------------------------------------------------------------------------------------------------------   
  def show_memory_verses

    user_id = params[:id]
    @mv_list = Array.new
    
    if (user_id)
      mem_vs = Memverse.find(:all, :conditions => ["user_id = ?", user_id], :order => "next_test ASC")
    else
      mem_vs = Memverse.find(:all, :include => :verse, :order => params[:sort_order])
    end
    
    # TODO: Get rid of this hash ... we can get everything we need from a single DB call
    
    mem_vs.each { |mv|
 
      memory_verse  = Hash.new
      memory_verse['id']            = mv.id
      memory_verse['user']          = mv.user.login
      memory_verse['verse_id']      = mv.verse.id
      memory_verse['verse']         = mv.verse.ref 
      memory_verse['efactor']       = mv.efactor
      memory_verse['status']        = mv.status
      memory_verse['last_tested']   = mv.last_tested
      memory_verse['next_test']     = mv.next_test
      memory_verse['test_interval'] = mv.test_interval
      memory_verse['n']             = mv.rep_n
      memory_verse['attempts']      = mv.attempts
      
      memory_verse['next']          = mv.next_verse
      memory_verse['prev']          = mv.prev_verse     
      memory_verse['first']         = mv.first_verse
      
      memory_verse['started']       = mv.created_at
      
      @mv_list << memory_verse
    }

  end

  # ----------------------------------------------------------------------------------------------------------
  # Remove a memory verse (Make sure this method is consistent with the one in memverses_controller
  # ----------------------------------------------------------------------------------------------------------   
  def destroy_mv

    # We need to remove inter-verse linkage
    dead_mv   = Memverse.find(params[:id])
    
    # Remove verse from memorization queue
    mem_queue = session[:mv_queue]
    
    # We need to check that there is a verse sequence and also that the array isn't empty
    if !mem_queue.blank?
      # Remove verse from the memorization queue if it is sitting in there
      mem_queue.delete(dead_mv.id)
    end

    dead_mv.remove_mv  # remove verse and sort out next and previous pointers 

    redirect_to :back
  end 

  
  # ----------------------------------------------------------------------------------------------------------
  # Show all users
  # ----------------------------------------------------------------------------------------------------------   
  def show_users
    
    period = params[:period] || 'All'
    @user_list = Array.new
    
    case period
      when 'Today' then
        @user_list = User.find(:all, :order => params[:sort_order], :conditions => ["created_at > ?", Date.today]) 
      when 'Active' then 
          User.find(:all, :order => params[:sort_order]).each { |user|
            if Date.today == user.last_activity_date
              @user_list << user
            end
          }
      when 'Pending' then
        @user_list = User.find(:all, :order => params[:sort_order], :conditions => ["state = ?", "Pending"])         
      when 'All' then
        @user_list = User.find(:all, :order => params[:sort_order])   
    end
  end    
  
  # ----------------------------------------------------------------------------------------------------------
  # Show all churches
  # ----------------------------------------------------------------------------------------------------------   
  def show_churches
    @church_list = Array.new
    @church_list = Church.find(:all, :order => "users_count DESC")
  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Show Church Members
  # ----------------------------------------------------------------------------------------------------------  
  def show_church
    
    @page_title = "Church Members"
    @tab        = "churches"

    if params[:church]
      @church         = Church.find(params[:church])
      @church_members = @church.users
    else
      flash[:notice]  = "No church selected"
      redirect_to :action => 'show_churches'
    end

  end     
  
  # ----------------------------------------------------------------------------------------------------------
  # Update users counter cache for churches 
  # TODO: for some reason this occasionally gets out of synch ... possibly when editing churches manually
  # ---------------------------------------------------------------------------------------------------------- 
  def update_church_users_counter 
    Church.reset_column_information  
    Church.all.each do |c|  
      c.update_attribute :users_count, c.users.length  
    end
    redirect_to :action => 'show_churches'
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Update users counter cache for countries 
  # TODO: for some reason this occasionally gets out of synch ... not sure why
  # ---------------------------------------------------------------------------------------------------------- 
  def update_country_users_counter 
    Country.reset_column_information  
    Country.all.each do |c|  
      c.update_attribute :users_count, c.users.length  
    end
    redirect_to :action => 'show_countries'
  end

  # ----------------------------------------------------------------------------------------------------------
  # Fix corrupted counter cache - does this for a single country
  # ----------------------------------------------------------------------------------------------------------   
  def update_country_user_count
    c = Country.find(params[:id])
    c.update_attribute :users_count, c.users.length
    redirect_to :action => 'show_countries'
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Fix corrupted counter cache - does this for a single state
  # ----------------------------------------------------------------------------------------------------------   
  def update_state_user_count
    c = AmericanState.find(params[:id])
    c.update_attribute :users_count, c.users.length
    redirect_to :action => 'show_states'
  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Fix corrupted counter cache - does this for a single church
  # ----------------------------------------------------------------------------------------------------------   
  def update_church_user_count
    c = Church.find(params[:id])
    c.update_attribute :users_count, c.users.length
    redirect_to :action => 'show_churches'
  end    
  
  # ----------------------------------------------------------------------------------------------------------
  # Show all countries
  # ----------------------------------------------------------------------------------------------------------   
  def show_countries
    
    @country_list = Array.new
    
    all_country_list = Country.find(:all)
    all_country_list.each { |country|
      if country.users_count != 0
        @country_list << country
      end  
    }

  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Show all states
  # ----------------------------------------------------------------------------------------------------------   
  def show_states
    
    @state_list = Array.new
    
    all_state_list = AmericanState.find(:all)
    all_state_list.each { |us_state|
      if us_state.users_count != 0
        @state_list << us_state
      end  
    }

  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Edit a user
  # ----------------------------------------------------------------------------------------------------------   
  def edit_user
    
    # -- Tabs and Title --
    @tab = "users"    
    @page_title = "Memverse : Edit User"
    
    # -- Display Form --
    @user           = User.find(params[:id])
    @user_country   = @user.country ? @user.country.printable_name : ""
    @user_church    = @user.church ?  @user.church.name : ""
    
    # -- Process Form --
    if request.put? # For some reason this is a 'put' not a 'post'
      if @user.update_profile(params[:user])
        flash[:notice] = "Profile successfully updated"
        redirect_to :action => 'search_users'
      else
        flash[:notice] = "Couldn't update user. Possible duplicate email or username."        
        render :action => edit_user
      end
    end
    
    
  end # method: update_profile
  
  # ----------------------------------------------------------------------------------------------------------
  # Update a user
  # ----------------------------------------------------------------------------------------------------------   
  def update_user
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "User successfully updated"
      redirect_to :action => 'show_users'
    else
      render :action => edit_user
    end
  end   
  
  # ----------------------------------------------------------------------------------------------------------
  # Delete a user -- DON'T USE THIS, Use 'delete_account' user method instead
  # ----------------------------------------------------------------------------------------------------------   
  def destroy_user
    
    dead_user = User.find(params[:id])
    
    dead_user.delete_account   
    
    redirect_to :action => 'search_users'   
  end    

  # ----------------------------------------------------------------------------------------------------------
  # Delete a church
  # ----------------------------------------------------------------------------------------------------------   
  def destroy_church
    
    dead_church = Church.find(params[:id])
    
    # We need to handle the removal of a church with users better
    # -- TODO: Insert code here --
    
    dead_church.destroy    
    redirect_to :action => 'show_churches'   
  end     
  
  
end

