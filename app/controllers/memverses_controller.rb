# coding: utf-8

# * Add client side verse memorization feedback
# - Add moderators for different translations
# - Add nice, explanatory pop-up boxes using jQuery
# - Allow for idle verses
# - Add better verse search - allow for missing search parameters to return, for instance, all translations of a given verse
# ? Allow users to enter first letter of each word when memorizing
# ? Allow for multiple groups

# --- Change Log -------------------------------------------------------------------------------------------
#
# 03/14/09 : Added most popular verses
# 03/15/09 : Linked adjacent memory verses -- not yet displayed as a linked memory verse, though.
# 03/21/09 : Added confirmation when verse is correctly entered on test page.
# 03/22/09 : Added a pre-login tutorial page
# 03/24/09 : Added RSS news feed on home page
# 03/24/09 : Added verse of the day on home page
# 03/30/09 : Exclude current memory verses from list of popular verses on "Add verse" page
# 03/30/09 : Solved problem of single quotes in verses - used escape_javascript()
# 04/01/09 : Added daily time estimate
# 04/03/09 : Position cursor in memorization box on page load
# 04/04/09 : Can now delete a memory verse
# 04/04/09 : Properly deals with whitespace at the end of verses and guesses
# 04/04/09 : Added interface to ESV API
# 04/05/09 : Added user account page
# 04/11/09 : Add pop-up for popular verses on mouseover
# 04/12/09 : Added KJV
# 04/16/09 : Added daily/weekly reminder emails
# 04/25/09 : Better feedback on "Add Verse" page and now clear entry box after add.
# 04/26/09 : Added links to tutorial and description of SuperMemo algorithm
# 05/04/09 : Added display of previous verse when testing longer memory verses.
# 05/11/09 : Bug fix: display of popular verses after 'quick add' - no longer includes your own verses
# 05/11/09 : Bug fix: doesn't display random previous verse when done memorizing for the day
# 05/12/09 : Added database table for popular verses
# 05/16/09 : Added display for popular verses
# 05/24/09 : Now keeping track of user progress - no graph yet, though
# 05/25/09 : Added drilling module
# 05/27/09 : Send reminders to users who haven't activated account
# 06/04/09 : Added last_activity_date to Admin "User" view. Added view for new users added today
# 06/04/09 : Use client-side javascript to sort User table
# 06/04/09 : Highlight user's verses in popular verses table
# 06/07/09 : Added progress graph
# 06/20/09 : Don't allow eFactor to go above 3.0 and set minimum to 1.2
# 06/21/09 : New color scheme
# 07/03/09 : New layout - menu tabs at the top now
# 07/05/09 : Added reverse memory i.e. matching reference to text
# 07/15/09 : Removed autocomplete for reference testing
# 07/15/09 : Fixed error that was preventing activated users with no verses from getting a reminder
# 08/04/09 : Remove carriage returns and extra whitespace in entered verses
# 08/08/09 : Fixed error in reference test caused when user hits browsers back button after test is finished
# 08/08/09 : Added leaderboard
# 08/08/09 : Skip memorized verses in long sequences
# 08/09/09 : Added notification when a verse is memorized
# 08/30/09 : Added time spent to progress chart
# 08/30/09 : Randomized reference recall test to 10 verses out of 50 most difficult
# 08/30/09 : Report incorrect verses at end of reference test
# 09/01/09 : Added support for Afrikaans bible
# 09/03/09 : Added Spurgeon's Morning devotional
# 09/09/09 : Allow users to edit verses which don't already have multiple users
# 09/14/09 : Verification admin is so Web 2.0
# 09/27/09 : Added new flash notice for users who are the second user of a verse. An exhortation to patience.
# 09/27/09 : Lengthened reminder period for inactive people.
# 09/27/09 : Added Swedish FolkBibeln
# 10/01/09 : Added countries and churches; tweaked email reminders to account for logins
# 10/05/09 : Optimized "popular_verses" method to reduce load times on add_verse page
# 10/17/09 : Psalm is now a book of the bible. Yay. Autocomplete for reference test. Fixed spacing of pop-up verses
# 10/30/09 : Bug fix: add_verse view -- moved observe field out of field form i.e. allow DOM element to be closed before observing
# 10/30/09 : Bug fix: calculated new interval using *new* efactor
# 11/01/09 : Tweaked algorithm for more regular revision in early stages of memorization. N=2 has interval=4 and intial efactor now 1.5
# 11/06/09 : Sort verses by book on "My Verses" page
# 11/08/09 : Created a starter pack of verses to get people started
# 11/16/09 : Added a blog
# 11/20/09 : Added custom counter cache for number of verses memorized/learning
# 11/22/09 : No longer able to add the same verse in two different translations - was causing linkage errors
# 12/09/09 : Added New Living Translation. Removed New World Translation
# 12/10/09 : No longer need to memorize to end of passage that one knows
# 12/10/09 : Upcoming verses module improved but still needs work
# 12/10/09 : Add intervals for reference test
# 12/20/09 : Added table to capture daily statistics
# 12/20/09 : Allow users to report verses with errors
# 12/21/09 : Added country competition - changed leaderboard layout
# 12/21/09 : Changed Philemon abbreviation - was conflicting with Philippians
# 12/21/09 : Added graph of global stats
# 12/26/09 : Bug fix: practice module was getting stuck on a verse because subsequent verses weren't being added since they weren't due for testing
# 12/26/09 : Added "Print my memory verses"
# 01/10/10 : Bug fix: Handle titleization of "Song of Songs"
# 01/10/10 : Bug fix: Pagination now works on blog; form_name wasn't being passed as a parameter
# 01/13/10 : Added manual activation, check for session variable in mark_test and mark_drill
# 02/01/10 : Feedback now optional once interval reaches 60 days
# 02/07/10 : No longer need to type dash, congratulations on milestones, fixed NKJ verification
# 02/15/10 : Added mnemonics for verses
# 02/25/10 : Added unsubscribe link to reminder emails, decrease email reminder frequency more quickly
# 03/05/10 : Started adding support for Spanish
# 03/09/10 : Added indexes for performance gains
# 04/04/10 : Bug fix: added unique index to prevent duplicate memverse entries and reinforced with client side behavior
# 04/06/10 : Added pages showing state/country members, added event feed for churches, states and countries
# 06/28/10 : New feature: add entire chapters
# 08/14/10 : New feature: launch of solo progression track
# 12/01/10 : New feature: QuickMem (now with Javascript)
# 01/06/11 : New feature: Multi-verse management (delete)
# 02/11/11 : ** Converted to Rails 3.0.3 and Ruby 1.9.2 **

class MemversesController < ApplicationController
  
  before_filter :authenticate_user!, :except => [:memverse_counter, :feedback]
  
  # Added 4/7/10 to prevent invalid authenticity token errors
  # http://ryandaigle.com/articles/2007/9/24/what-s-new-in-edge-rails-better-cross-site-request-forging-prevention
  protect_from_forgery :only => [:create, :update, :destroy]

  prawnto :prawn => { :top_margin     => 50 }
  prawnto :prawn => { :bottom_margin  => 50 }
  prawnto :prawn => { :left_margin    => 50 }
  prawnto :prawn => { :right_margin   => 50 }

  respond_to :html, :pdf
  
  add_breadcrumb "Home", :root_path

  # ----------------------------------------------------------------------------------------------------------
  # Home / Start Page
  # ----------------------------------------------------------------------------------------------------------   
  def index
    
    @tab = "home"

    if current_user.needs_quick_start?
      redirect_to :controller => "home", :action => "quick_start" and return        
    end
 
    @due_today	= current_user.due_verses unless mobile_device?
    @overdue		= current_user.overdue_verses unless mobile_device?
    
    # Level information
    quests_remaining = current_user.current_uncompleted_quests.length
    @quests_to_next_level = quests_remaining==1 ? "one quest" : quests_remaining.to_s + " quests"
    
    # Has this user added any verses?
    # @user_has_no_verses           = (current_user.learning == 0) && (current_user.memorized == 0)
    # Does this user need more verses?
    # @user_has_too_few_verses      = (current_user.learning + current_user.memorized <= 5)
    
    # Otherwise, show some nice statistics and direct user to memorization page if necessary
    if (!@user_has_no_verses)      
      mv = Memverse.find(:first, :conditions => ["user_id = ?", current_user.id], :order => "next_test ASC")
      if !mv.nil?
        @user_has_test_today = (mv.next_test <= Date.today)
      end
      
      unless flash[:error] or flash[:notice] or !current_user.first_verse_today # Show flash with verses due and workload unless another flash or done with review
        flash.now[:notice] = t('messages.today_msg_html', :due_today => current_user.due_verses, :time => current_user.work_load)
      end

    end

    # === Get Recent Tweets ===    
    @tweets1 = Tweet.where(:importance => 1..2).limit(12).order("created_at DESC")  # Most important tweets
    @tweets2 = Tweet.where(:importance => 3..4).limit(12).order("created_at DESC")  # Moderate importance
            
    # === RSS Devotional ===    
    dd = Rails.cache.fetch(["devotion", Date.today.month, Date.today.day], :expires_in => 24.hours) do
      Devotion.where(:name => "Spurgeon Morning", :month => Date.today.month, :day => Date.today.day ).first || Devotion.daily_refresh
    end

    @dev_ref  = dd.try(:ref) || ""
    @devotion = dd.try(:thought) || ""     
    
    # === Verse of the Day ===   
    @votd_txt, @votd_ref, @votd_tl, @votd_id  = verse_of_the_day()
    
    # === Check for incomplete profile ===
    if current_user.country_id == 226 and current_user.american_state.nil?      
      link = "<a href=\"#{update_profile_path}\">Please update your profile to reflect your state.</a>"
      if flash[:notice] 
        flash[:notice] << " #{link} " 
      else
        flash[:notice] = "#{link}"
      end
    end
                      
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # AJAX: Memorized verses
  # ----------------------------------------------------------------------------------------------------------  
  def memverse_counter
    total_verses = Memverse.memorized.count
    render :json => { :total_verses => total_verses }
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Starter pack - select verses from top ten verses
  # ----------------------------------------------------------------------------------------------------------  
  def starter_pack
    add_breadcrumb I18n.t("page_titles.quickstart"), :starter_pack_path
    @tab = "home"
    @sub = "addvs"
    
    @translation = params[:translation].gsub("/", "")  # remove trailing slash if necessary
    
    # TODO: get rid of the archaic 'IS NOT NULL' syntax
    @suggestions = Popverse.find( :all,
                                  :conditions => ["#{@translation} IS NOT NULL"],
                                  :select => "pop_ref, #{@translation}_text, #{@translation}", 
                                  :limit => 12)

  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Verse of the day
  # ----------------------------------------------------------------------------------------------------------  
  def verse_of_the_day
    
    # Find a popular verse eg: ['Jn 3:16', [['NIV', id] ['ESV', id]]]
    verse     = popular_verses(100).sample # get 100 most popular verses - pick one at random
            
    # Pick out a translation in user's preferred translation or at random
    if verse  # TODO: Make bootstrapping of DB easier ... would be better to seed DB
      verse_ref         = verse[0]     
      verse_tl          = verse[1].select{ |tl| tl[0] == current_user.translation }.compact.first || verse[1].sample
      verse_id          = verse_tl[1]
      verse_translation = verse_tl[0]
      
      verse_txt         = Verse.find(verse_id).text
      
      return verse_txt, verse_ref, verse_translation, verse_id
    else
      return "Be joyful always", "1 Thess 5:16", "NIV", nil
    end
        
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # User Statistics
  # ---------------------------------------------------------------------------------------------------------- 
  def user_stats
    
    @my_verses    = Array.new
    @status_table = Hash.new(0)
    
    mem_vs = Memverse.find(:all, :conditions => ["user_id = ?", current_user.id])
  
    mem_vs.each { |mv|
       
      vs            = Verse.find(mv.verse_id)
      verse         = db_to_vs(vs.book, vs.chapter, vs.versenum)
 
      @status_table[mv.status]  += 1

    }
    
    @pop_verses = Popverse.find(:all, :limit => 15)
    
  end

  # ----------------------------------------------------------------------------------------------------------   
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------   
  def pop_verses

    @tab = "home" 
    @sub = "popvs"
    
    add_breadcrumb I18n.t("home_menu.Popular Verses"), :popular_verses_path
         
    @page       = [params[:page].to_i, 99].min     # page number
    @page_size  = 20                               # number of verses per page
       
    @vs_list = Popverse.find( :all, :limit => @page_size, :offset => @page*@page_size )    
  end 


  # ----------------------------------------------------------------------------------------------------------   
  # Display a single verse TODO: We shouldn't use this ... there is a show method in the verse controller
  # ---------------------------------------------------------------------------------------------------------- 
  # def show_vs
    # @verse = Verse.find(params[:vs])
  # end

  # ----------------------------------------------------------------------------------------------------------   
  # Display a single memory verse or several verses as POSTed from manage_verses
  # ----------------------------------------------------------------------------------------------------------  
  def show
  	  	
    @tab = "home"
    @sub = "manage"  	  	
  	  	
    mv_ids = params[:mv] 

    # ==== Displaying a single verse ====
    if params[:id]
    
      @mv         = Memverse.find(params[:id])
      @verse      = @mv.verse    
    
      add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path
      add_breadcrumb "#{@verse.book} #{@verse.chapter}:#{@verse.versenum}", {:action => 'show', :id => params[:id] }
      
      @user_tags  = @mv.tags
      @tags       = @verse.tags
      # @other_tags = @verse.all_user_tags  # TODO: this is a very expensive transaction
      
      @next_mv = @mv.next_verse || @mv.next_verse_in_user_list
      @prev_mv = @mv.prev_verse || @mv.prev_verse_in_user_list

    # ==== Displaying multiple verses ====    
    elsif (!mv_ids.blank?) and (params[:Show])

      @mv_list = Memverse.find(mv_ids, :include => :verse)
      @mv_list.sort! # Sort by book. TODO: Pass paramaters from manage_verses and sort by that order...
      
      add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path
      add_breadcrumb I18n.t("page_titles.view_vs_s"), "/memverses/show"
      
    # Error: verse ID's passed with request to delete  
    elsif (!mv_ids.blank?) and (params[:Delete])

      flash[:notice] = "JavaScript is required to delete verses. Please enable, then refresh page and try again."
      redirect_to :action => 'manage_verses' and return

    elsif (mv_ids.blank?)
    	
      flash[:notice] = "Please select verses using the checkboxes in the first column."
      redirect_to :action => 'manage_verses' and return
      
    else
    	
      redirect_to :action => 'manage_verses' and return
      
    end
    
    respond_to do |format|
      format.html
      format.pdf { render :layout => false } # if params[:format] == 'pdf'
        prawnto :filename => "Memverse.pdf", :prawn => { }
    end    
    
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Display prompterizations/mnemonics for single memory verse or several verses as POSTed from manage_verses
  # ----------------------------------------------------------------------------------------------------------  
  def show_prompt
        
    @tab = "home"
    @sub = "manage"       
        
    mv_ids = params[:mv] 

  # ==== Verse IDs were passed from manage_verses or similar form ====    
    if (!mv_ids.blank?) and (params[:Prompt])

      @mv_list = Memverse.find(mv_ids, :include => :verse)
      @mv_list.sort! # Sort by book. TODO: Pass paramaters from manage_verses and sort by that order...
      
      add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path
      add_breadcrumb I18n.t("memverses.manage_verses.show_prompt"), {:action => "show_prompt", :controller => "memverses"}
      
    elsif (mv_ids.blank?)
      
      flash[:notice] = "Please select verses using the checkboxes in the first column."
      redirect_to :action => 'manage_verses' and return
      
    else
      
      redirect_to :action => 'manage_verses' and return
      
    end
    
    respond_to do |format|
      format.html
      format.pdf { render :layout => false } # if params[:format] == 'pdf'
        prawnto :filename => "Memverse.pdf", :prawn => { }
    end    
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # In place editing support for tag addition
  # ----------------------------------------------------------------------------------------------------------    
  def add_verse_tag
    @mv = Memverse.find(params[:id])
    new_tag = params[:value].titleize # need to clean this up with hpricot or equivalent


    # Notes on using the acts_as_taggable_on gem
    #
    # 1. Owned tags and regular tags are handled in two different modules in the library
    # 2. The method 'tag_list' only returns tags without owners. The method 'all_tags_list' returns all tags
    # 3. user.tag(mv, :with => 'TagA', :on => :tags) *replaces* any prior tags. 
    # 4. mv.tag_list = "tagC, tagD" does not appear to overwrite an existing tag list
    
    if !new_tag.empty?
      tag_list = @mv.all_tags_list.to_s + ", " + new_tag
      current_user.tag(@mv, :with => tag_list, :on => :tags)  # We're doing this for now to track which users are tagging
      
      # Update verse model with most popular tags
      # spawn_block(:argv => "spawn-update-vs-tags") do
        @mv.verse.update_tags
      # end
 
      render :text => new_tag
    else
      render :text => "[Enter tag name here]"
    end
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Remove a verse tag
  # ---------------------------------------------------------------------------------------------------------- 
  def remove_verse_tag    
    dead_tag = ActsAsTaggableOn::Tagging.find(:first, :conditions => {:tag_id => params[:id], :taggable_id => params[:mv], :taggable_type => 'Memverse' })
    
    if dead_tag   	
      dead_tag.destroy
	    # We should remove the tag if it is no longer tagging anything
	    if ActsAsTaggableOn::Tag.find(params[:id]).taggings.length == 0
	      ActsAsTaggableOn::Tag.find(params[:id]).destroy
	    end    
    end

    redirect_to(:action => 'show', :id => params[:mv])
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Edit a verse
  # ----------------------------------------------------------------------------------------------------------   
  def edit_verse
    @verse = Memverse.find(params[:id]).verse 
    add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path
    add_breadcrumb "Edit #{@verse.book} #{@verse.chapter}:#{@verse.versenum}", {:action => 'edit_verse', :id => params[:id] }
  end 

  # ----------------------------------------------------------------------------------------------------------
  # Update a verse
  # ----------------------------------------------------------------------------------------------------------   
  def update_verse
    @verse = Verse.find(params[:id])
    if @verse.update_attributes(params[:verse])
      flash[:notice] = "Verse successfully updated"
      redirect_to :action => 'manage_verses'
    else
      render :action => edit_verse
    end
  end   


  # ----------------------------------------------------------------------------------------------------------
  # Verify a verse
  # ----------------------------------------------------------------------------------------------------------  
  def toggle_verse_flag
    @verse = Verse.find(params[:id])
    @verse.error_flag = !@verse.error_flag
    @verse.save
    render :partial => 'flag_verse', :layout => false
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Toggle verse from 'Active' to 'Pending' status
  # ----------------------------------------------------------------------------------------------------------  
  def toggle_mv_status
    @mv = Memverse.find(params[:id])
    
    if @mv && @mv.status == 'Pending'
    	@mv.status = @mv.test_interval > 30 ? "Memorized" : "Learning"
    else
    	@mv.status = 'Pending'
    end
    @mv.save
    render :partial => 'mv_status_toggle', :layout => false
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Table of popular verses
  # 
  # Returns data structure as follows:
  #  [Verse0, [translation_0, id_0], [translation_1, id_1]]
  #  [Verse1, [tranalation_0, id_0]
  #  etc.
  # Popular verses accesses the following DB tables:
  #   - Verse
  #   - Memory_Verse
  #   - User
  #
  # NB: MIRROR ANY CHANGES HERE TO ADMIN_CONTROLLER !!!!!!
  # ---------------------------------------------------------------------------------------------------------- 
  def popular_verses(limit = 8, include_current_user_verses = true)

    pop_verses = Array.new
    
    # Changing the number of verses returned doesn't buy anything because you have to access entire memory verse table
    pop_mv = Popverse.find(:all) 
    
    pop_mv.each { |vs|
    
      verse    = vs.pop_ref
         
      # Only include verse in list of popular verses if current_user doesn't have it already
      errorcode, book, chapter, versenum = parse_verse(verse) 
      if include_current_user_verses or !current_user.has_verse?(book, chapter, versenum)
  
  
        avail_translations = [["NIV", vs.niv, vs.niv_text],
                              ["ESV", vs.esv, vs.esv_text],
                              ["NAS", vs.nas, vs.nas_text],
                              ["NKJ", vs.nkj, vs.nkj_text],
                              ["KJV", vs.kjv, vs.kjv_text]]
                                                                     
        translations = Array.new
        avail_translations.each { |translation|
          if !translation[1].nil?
            translations << translation
          end
        }
                                                          
        pop_verses << [verse, translations]
      end
    }
    
    return pop_verses[0..limit]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Save memory verse for user and update all links
  # ---------------------------------------------------------------------------------------------------------- 
  def save_mv_for_user(vs)
    # Save verse as a memory verse for user      
    mv = Memverse.new
    mv.user_id      = current_user.id
    mv.verse_id     = vs.id
    mv.efactor      = 2.0  # Initial seed value
    mv.last_tested  = Date.today
    mv.next_test    = Date.today # Start testing tomorrow
    mv.status       = current_user.overworked? ? "Pending" : "Learning"
    # Add multi-verse linkage  
    mv.prev_verse   = mv.get_prev_verse
    mv.next_verse   = mv.get_next_verse
    mv.first_verse  = mv.get_first_verse
    mv.save # TODO need to find a way to ensure no duplication
    
    # Adding inbound links
    if mv.prev_verse
      prior_vs             = Memverse.find(mv.prev_verse)
      prior_vs.next_verse  = mv.id
      prior_vs.save
    end
    if mv.next_verse
      subs_vs             = Memverse.find(mv.next_verse)
      subs_vs.prev_verse  = mv.id
      subs_vs.first_verse = mv.first_verse || mv.id # || returns first operator that satisfies condition
      subs_vs.save
      # Updating starting point for downstream verses 
      update_downstream_start_verses(subs_vs)
    end
    
    # TODO: Check once more for duplication at this point and then save  
    
  end # end of save verse as a memory verse for user    
  

  # ----------------------------------------------------------------------------------------------------------
  # AJAX Verse Add
  # ---------------------------------------------------------------------------------------------------------- 
  def ajax_add
  	vs  = Verse.find(params[:id])
  	
    if current_user.has_verse_id?(vs)
      msg = "Previously Added"
    else
      # Save verse as a memory verse for user      
      save_mv_for_user(vs)  # TODO rather use a model method ... this is archaic!
      msg = "Added"
    end  	
  	
  	render :json => {:msg => msg }
  	
  end
  

  # ----------------------------------------------------------------------------------------------------------
  # Add an existing memory verse
  # ---------------------------------------------------------------------------------------------------------- 
  def quick_add
    
    @tab = "home"
    @sub = "addvs"    
    
    add_breadcrumb I18n.t("home_menu.Add Verse"), :add_verse_path
    
    vs = Verse.find(params[:vs])
      
    if your_mv = current_user.has_verse?(vs.book, vs.chapter, vs.versenum)
      flash.now[:notice] = "You already have #{your_mv.verse.ref} in the #{your_mv.verse.translation} translation in your list of memory verses."
    else
      # Save verse as a memory verse for user      
      save_mv_for_user(vs) # TODO rather use a model method ... this is archaic!
      flash_for_successful_verse_addition(vs)
    end
    render(:template => 'memverses/add_verse.html.erb')     
  end

  # ----------------------------------------------------------------------------------------------------------
  # Add an entire chapter
  # TODO: pass in entire chapter if searching again proves to be too slow
  # TODO: doesn't handle case where user already has some verses in a different translation ... just inserts new verses in the current translation
  # ---------------------------------------------------------------------------------------------------------- 
  def quick_add_chapter
    
    ch          = Verse.find(params[:vs]).entire_chapter
    book        = ch[0].book
    chapter     = ch[0].chapter
    translation = ch[0].translation
    
    
    if ch.include?(nil)
      flash[:error] = "Sorry, we do not have all the verses for that chapter"
    elsif current_user.has_chapter?(book, chapter)
      flash[:notice] = "You already have #{book} #{chapter} in the #{translation} translation in your list of memory verses."
    else
      ch.each { |vs| 
        if your_mv = current_user.has_verse?(vs.book, vs.chapter, vs.versenum)
          # Don't add
          # flash[:notice] = "You already have #{your_mv.verse.ref} in the #{your_mv.verse.translation} translation in your list of memory verses"
        else
          # Save verse as a memory verse for user      
          save_mv_for_user(vs)
          # flash_for_successful_verse_addition(vs)
        end    
      }
      flash[:notice] = "#{book} #{chapter} in the #{translation} translation has been added to your list of memory verses."
    end
    
    render(:template => 'memverses/add_verse.html.erb')     
  end



  # ----------------------------------------------------------------------------------------------------------
  # Add a new memory verse
  # ----------------------------------------------------------------------------------------------------------   
  def add_verse

    @tab = "home"
    @sub = "addvs"    
    
    add_breadcrumb I18n.t("home_menu.Add Verse"), :add_verse_path
    
    errorcode = false
    
    ref = params[:verse]
    txt = params[:versetext]
    tl  = params[:translation]
    
    errorcode, book, chapter, verse = parse_verse(ref)
    
    # <--- At this point the book name should already be translated into English --->
    
    if request.post? and txt.blank? # ie. a form is being submitted
      errorcode = 4 # No text in entry box
    end
    
    if (!errorcode) and (!verse_too_long?(txt)) # If verse is ok and not too long
      # Check whether verse is already in DB
      if vs = verse_in_db(book, chapter, verse, tl)
        flash.now[:notice] = "Verse is already in database. Added to your memory list."       
      else      
        # Save verse to database of verses     
        vs = save_verse_to_db(tl, book, chapter, verse, txt.gsub!(/\s+/," "))
        flash.now[:notice] = "Verse has been saved."
      end
      
      if your_mv = current_user.has_verse?(vs.book, vs.chapter, vs.versenum)
        flash.now[:notice] = "You already have #{your_mv.verse.ref} in the #{your_mv.verse.translation} translation in your list of memory verses."
      else
        # Save verse as a memory verse for user      
        save_mv_for_user(vs)
        flash_for_successful_verse_addition(vs)
        params[:versetext] = ""
      end
      
    else
      flash.now[:notice] = case errorcode
        when 1 then "Bible reference is incorrectly formatted. Format should be John 3:16 or John 3 vs 16"
        when 2 then "#{book} is not a valid book of the Bible"
        when 3 then 'Please enter each verse individually and remove any verse numbering or footnote information.'
        when 4 then "Please enter the text for your memory verse. Please do not include any verse numbering or footnote information."
        else        "The verse you entered is longer than the longest verse in the Bible! Please enter one verse at a time. Consecutive verses will be grouped into a single memory passage."         
      end
      flash.now[:notice].html_safe
      render(:template => 'memverses/add_verse.html.erb')
    end
    
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Add a new memory verse (new version)
  # ----------------------------------------------------------------------------------------------------------   
  def add_verse_quick

    @tab = "home"
    @sub = "addvs"    
    
    add_breadcrumb I18n.t("home_menu.Add Verse"), :add_verse_path
    
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Notification after verse added
  # ----------------------------------------------------------------------------------------------------------   
  def flash_for_successful_verse_addition(vs)
    if vs.memverses.length == 2
      flash.now[:notice] = "#{vs.ref} has been added to your list of memory verses. Since you are only the second user to start memorizing this verse, it has not yet been verified by a moderator. It will be verified within the next 24 hours so please be patient if you see an error. "
    else
      flash.now[:notice] = "#{vs.ref} has been added to your list of memory verses. "
    end

    # Add link to next verse in same translation
    if next_verse = vs.following_verse
      link = "<a href=\"#{url_for(:action => 'quick_add', :vs => next_verse)}\">[Add #{next_verse.ref}]</a>"
      flash.now[:notice] << " #{link} "
    end
      
  end

  # ----------------------------------------------------------------------------------------------------------
  # Delete a memory verse
  # TODO: make this a method of Memverse.rb
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
    
    redirect_to :action => 'manage_verses'   
  end 
 
  # ----------------------------------------------------------------------------------------------------------
  # Manage verses - used to display verse management page to user
  # ----------------------------------------------------------------------------------------------------------
  def manage_verses
    
    @tab = "home"
    @sub = "manage"
    
    add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path

    # TODO: select only a) verse reference and b) verse translation to speed up this page and use less memory
    # TODO: include tags if possible

    if params[:sort_order]
      @my_verses = current_user.memverses.includes(:verse).order(params[:sort_order])
    else
      # default to canonical sort
      @my_verses = current_user.memverses.includes(:verse).order('verses.book_index, verses.chapter, verses.versenum')      
    end      

    respond_to do |format| 
      format.html
      format.pdf { render :layout => false } if params[:format] == 'pdf'
        prawnto :filename => "Memverse.pdf", :prawn => { }
    end
      
  end 
 
  # ----------------------------------------------------------------------------------------------------------
  # Manage verses - used to handle the manage verses form (delete a lot of verses or show selected)
  # TODO: see above ... should re-use code from above and call a model method
  # ----------------------------------------------------------------------------------------------------------
  def delete_verses
    
    mv_ids = params[:mv]

    if (!mv_ids.blank?) and (params['Delete'])
      mv_ids.each { |mv_id|   
      
        # Find verse in DB
        logger.debug("*** Finding mv with id: #{mv_id}")
        mv = Memverse.find(mv_id)
           
        # Remove verse from memorization queue
        mem_queue = session[:mv_queue]        
        # We need to check that there is a verse sequence and also that the array isn't empty
        if !mem_queue.blank?
          logger.debug("*** Found session queue with verses")	
          # Remove verse from the memorization queue if it is sitting in there
          mem_queue.delete(mv_id)
        end

        mv.remove_mv

      }
      flash[:notice] = "Verse deletion complete."
      redirect_to :action => 'manage_verses'
    elsif (mv_ids.blank?)
      flash[:notice] = "Action not performed as no verses were selected."
      redirect_to :action => 'manage_verses'
    else
      redirect_to :action => 'manage_verses'
    end
      
  end 
 
  # ----------------------------------------------------------------------------------------------------------
  # Check whether any translations of entered verse are in DB
  # ----------------------------------------------------------------------------------------------------------    
  def avail_translations
    
    ref = params[:verse]
    
    errorcode, book, chapter, versenum = parse_verse(ref) 

    if (!errorcode) # If verse is ok
      
      @avail_chapters = Array.new
      
      # Check whether verse is already in DB
      @avail_translations = Verse.find( :all, 
                                        :conditions => ["book = ? and chapter = ? and versenum = ?", 
                                                         full_book_name(book), chapter, versenum])
      # Check whether entire chapter is available                                                   
      @avail_translations.each { |vs| 
        if !vs.entire_chapter.include?(nil) # if all verses are in db
          @avail_chapters << vs.translation    
        end
      }                                                               
    end
    
    respond_to do |format|
      format.html { render :partial=>'avail_translations', :layout=>false }
      format.xml  { render :xml => @avail_translations }
      format.json { render :json => @avail_translations }
    end
          
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Get Memverse from Queue - returns nil if queue is empty
  # ----------------------------------------------------------------------------------------------------------   
  def get_memverse_from_queue
    
    rest_of_multiverse = session[:mv_queue]
    
    # We need to check that there is a verse sequence and also that the array isn't empty
    if rest_of_multiverse and !rest_of_multiverse.empty?
      # TODO: The problem with removing the verse is that if the user doesn't get tested on the verse then they
      # won't see it again. We should probably only do the shift after the test has been scored.
      current_verse       = rest_of_multiverse.shift  # shift returns first element of array and removes it
      session[:mv_queue]  = rest_of_multiverse
      return Memverse.find( current_verse )
    else
      session[:mv_queue] = nil # Clear the session just to be safe
      return nil
    end
  end


  # ----------------------------------------------------------------------------------------------------------
  # Put series of memory verses into memory queue. Stop if remaining verses are already memorized
  # Input: a memory verse
  # Output: returns first memory verse to be memorized
  # ----------------------------------------------------------------------------------------------------------

  def put_memverse_cohort_into_queue(mv, mode="test")
    
    mv_queue = Array.new
    
    # Jump to start of memory verse sequence and set return value ie. verse to be tested now
    if mv.prev_verse # this is not the first verse of a seqence -> locate first verse of sequence
      
      # if a) verse sequence is longer than 5 AND 
      #    b) user doesn't want to repeat memorized verses AND
      #    c) first verse is not due for memorization today AND
      #    d) it's been less than a month since the first verse was memorized AND
      #    e) we are testing, not drilling
      # THEN skip to first unmemorized verse
      if mv.sequence_length > 5 and mode == "test"
        initial_mv = mv.first_verse_due_in_sequence
      else
        initial_mv = Memverse.find( mv.first_verse )
      end
          
    else # this is the first verse of the sequence
      initial_mv = mv
    end
    
    x = initial_mv
    while x.next_verse and (x.more_to_memorize_in_sequence? or mode == "practice") # stop adding verses if user knows rest of passage
      # Add every subsequent verse
      x = Memverse.find(x.next_verse)
      mv_queue << x.id     
    end
    
    session[:mv_queue] = mv_queue
    return initial_mv
  end

  # ----------------------------------------------------------------------------------------------------------
  # Memorize
  # ----------------------------------------------------------------------------------------------------------   
  def test_verse
 
    @tab = "mem"  
    @show_feedback = true
    
    # If referring path is from the practice section then we need to clear the queue
    # TODO: maybe use a different session variable
    
    # First check for verses in session queue that need to be tested
    if mv = get_memverse_from_queue()
      # This verse needs to be memorized
      @verse            = mv.verse.ref
      @text             = mv.verse.text
      @mnemonic         = mv.verse.mnemonic if mv.needs_mnemonic?
      @current_versenum = mv.verse.versenum
      @show_feedback    = mv.show_feedback? || true  # default to true in case of nil something in first expression
      # Put memory verse into session
      session[:memverse] = mv.id  
    else
      # Otherwise, present the most overdue verse for memorization
      mv = Memverse.find( :first, 
                          :conditions => ["user_id = ?", current_user.id], 
                          :order      => "next_test ASC")
      if !mv.nil? # We've found a verse
         
        if mv.next_test <= Date.today
                  
          # Are there any verses preceding/succeeding this one? If so, we should test those first    
          if mv.prev_verse or mv.next_verse
            # put verses into session queue and begin with start verse
            mv = put_memverse_cohort_into_queue(mv, "test")
          end               
          # Put memory verse into session
          session[:memverse] = mv.id

          # This verse needs to be memorized
          @verse            = mv.verse.ref
          @text             = mv.verse.text 
          @mnemonic         = mv.verse.mnemonic if mv.needs_mnemonic?         
          @current_versenum = mv.verse.versenum    
          @show_feedback    = mv.show_feedback? || true  # default to true in case of nil something in first expression
          logger.debug("Show feedback for verse overdue: #{@show_feedback}. Interval is #{mv.test_interval} and request feedback is #{current_user.show_echo}")
        else
          # There are no more verses to be tested today
          @verse            = "No more verses for today"
          mv                = nil # clear out the loaded memory verse

          # Update progress report
          current_user.save_progress_report
          
          # Redirect user to a page of statistics and recommendations
          redirect_to :action => 'show_progress'   
          flash[:notice] = "You have no more verses to memorize today. Your next memory verse is due for review " + current_user.next_verse_due           
        end
        
      else # this user has no verses
        redirect_to :action => 'add_verse'
        flash[:notice] = "You should first add a few verses"       
      end
    end
    
    # --- Load prior verse if available
    if mv and mv.prev_verse
      prior_verse       = Memverse.find(mv.prev_verse).verse
      @prior_text       = prior_verse.text
      @prior_versenum   = prior_verse.versenum
    end
  
    # --- Load upcoming verses ---
    logger.debug("*** Mobile Device: #{mobile_device?}")
    @upcoming_verses = current_user.upcoming_verses() unless mobile_device?
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Select chapter to review
  # ----------------------------------------------------------------------------------------------------------   
  def chapter_explanation
    @tab = "mem"  
    @sub = "chrev" 
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Chapter Review"), :pre_chapter_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # Review an entire chapter
  # ----------------------------------------------------------------------------------------------------------   
  def test_chapter
 
    @tab = "mem"  
    @sub = "chrev"  
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Chapter Review"), {:action => 'test_chapter', :book_chapter => params[:book_chapter]}
    
    @show_feedback = true
    
    if params[:book_chapter].split.length == 3
      bk_num, bk_name, ch = params[:book_chapter].split
      bk = bk_num + " " + bk_name
    else
      bk, ch = params[:book_chapter].split      
    end

    logger.info("* Testing chapter: #{bk} #{ch}")
    
    @chapter      = current_user.has_chapter?(bk,ch)
    @bk_ch        = bk + " " + ch
    @verse        = 1
    @final_verse  = @chapter.length
            
  end

  # ----------------------------------------------------------------------------------------------------------
  # Memorize [AJAX]
  # ----------------------------------------------------------------------------------------------------------   
  def test_verse_quick
 
    @tab = "mem"  
    @sub = "mem"  
    @show_feedback = true
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    
    @mv 			= current_user.first_verse_today
        
    if @mv
      @show_feedback    = @mv.show_feedback? || true  # default to true in case of nil something in first expression        
      # --- Ok to test : Load prior verse if available
      if @mv.prev_verse
        @prev_mv        = Memverse.find(@mv.prev_verse)
        @prior_text     = @prev_mv.verse.text
        @prior_versenum = @prev_mv.verse.versenum
      end
    else # this user has no verses due at the moment
      if current_user.has_started?
      	
        if current_user.has_active?
          flash[:notice] = "You have no more verses to memorize today. Your next memory verse is due for review " + current_user.next_verse_due + "."
          redirect_to :action => 'show_progress' and return
        elsif current_user.auto_work_load # User will allow us to adjust work load and needs it
          current_user.adjust_work_load
          redirect_to test_verse_quick_path and return
        else # User won't allow us to activate verses, so we must tell him to.
          flash[:notice] = "You have no verses due for review today because none of your verses are active. Activate verses by clicking on the 'Pending' status."
          redirect_to manage_verses_path and return          
        end
               
      else
        redirect_to :action => 'add_verse' and return
        flash[:notice] = "You should first add a few verses."   
      end
    end
  
    # --- Load upcoming verses ---
    @upcoming_verses = current_user.upcoming_verses() unless mobile_device?
   
    # We should never receive a JS request for this URL but this is an attempted fix for the following error
    
		# ActionView::MissingTemplate: Missing template memverses/test_verse_quick with 
		# {:handlers=> [:prawn_xxx, :builder, :prawn, :prawn_dsl, :erb, :rjs, :rhtml, :rxml], 
		# :locale=>[:en, :en], 
		# :formats=>[:js, "application/ecmascript", "application/x-ecmascript", "*/*"]} 
		# in view paths "/app/views",     
    respond_to do |format|
      format.html
      format.js { redirect_to test_verse_quick_path }
    end
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Implement Supermemo Algorithm [AJAX]
  # ----------------------------------------------------------------------------------------------------------     
  def mark_test_quick
    
    # Find verse
    mv  = Memverse.find(params[:mv])
    q   = params[:q].to_i
        
    # Execute Supermemo algorithm
    newly_memorized = mv.supermemo(q)

    # Give encouragement if verse transitions from "Learning" to "Memorized"
    if newly_memorized
      msg = "Congratulations. You have memorized #{mv.verse.ref}."
      Tweet.create(:news => "#{current_user.name_or_login} memorized #{mv.verse.ref}", :user_id => current_user.id, :importance => 5)

      if current_user.reaching_milestone
      	milestone = current_user.memorized+1
      	
      	importance = case milestone
	      	when    0..    9 then 4
	      	when   10..  199 then 3
	      	when  200..  999 then 2
	      	when 1000..10000 then 1 
	      	else                  5
      	end
      	
        msg       << " That was your #{milestone}th memorized verse!"
        broadcast  = "#{current_user.name_or_login} memorized #{current_user.his_or_her} #{milestone}th verse"
        Tweet.create(:news => broadcast, :user_id => current_user.id, :importance => importance)
      end

      if mv.chapter_memorized?
        msg << " You have now memorized all of #{mv.verse.book} #{mv.verse.chapter}. Great job!"
        Tweet.create(:news => "#{current_user.name_or_login} memorized #{mv.verse.book} #{mv.verse.chapter}", :user_id => current_user.id, :importance => 3)          
      end

    end
   
    render :json => {:msg => msg }
      
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns the next verse to be tested - this is a service URL for a js routine
  # ---------------------------------------------------------------------------------------------------------- 
  def test_next_verse

    current_mv      = Memverse.find(params[:mv])
    
    mv              = current_mv.next_verse_due(false)
    mv_skip         = current_mv.next_verse_due(true)

    prior_mv        = mv && mv.prior_mv
    prior_mv_skip   = mv_skip && mv_skip.prior_mv
     
    if mv
      render :json => { :finished       => false, 
                        :mv             => mv, 
                        :mv_skip        => mv_skip, 
                        :prior_mv       => prior_mv, 
                        :prior_mv_skip  => prior_mv_skip }
    else
      render :json => { :finished => true }
    end
    
       
  end

  # ----------------------------------------------------------------------------------------------------------
  # Prepare for Reference Test
  # ----------------------------------------------------------------------------------------------------------
  def load_test_ref
    
    @tab = "mem" 
    
    ref_quizz         = Array.new
    ref_quizz_answers = Array.new
    ref_id            = Array.new
    
    # Find the 30 hardest (first) verses and pick 10 at random for the test
    if current_user.all_refs
      refs = Memverse.active.find( :all, 
                            :conditions => ["user_id = ?", current_user.id], 
                            :order      => "ref_interval ASC",
                            :limit      => 30 ).sort_by{ rand }.slice(0...10)
    else
      refs = Memverse.active.find( :all, 
                            :conditions => ["user_id = ? and prev_verse is ?", current_user.id, nil], 
                            :order      => "ref_interval ASC",
                            :limit      => 30 ).sort_by{ rand }.slice(0...10)      
    end
  
                          
    
    if refs.length >= 10
    
      # Put verses into session variable
      refs.each { |r|
        ref_quizz         << r.verse.text # TODO: if verse has duplicates we should show prior verse
        ref_quizz_answers << [r.verse.book, r.verse.chapter.to_i, r.verse.versenum.to_i] 
        ref_id            << r.id
      }
  
      # Create session variables
      session[:ref_test]          = ref_quizz
      session[:ref_soln]          = ref_quizz_answers
      session[:ref_id]            = ref_id
      session[:ref_test_cntr]     = 0
      session[:reftest_correct]   = 0    
      session[:reftest_grade]     = 0    
      session[:reftest_answered]  = 0
      session[:reftest_length]    = refs.length
      session[:reftest_incorrect] = Array.new
      
      # Start Test
      redirect_to :action => 'test_ref'
    else
      flash[:notice] = "You must have 10 verse references in your account before you can take the reference recall test."
      redirect_to :action => 'index'
    end
    
  end

  def explain_exam
    @tab = "mem"
    @sub = "acctest"
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Accuracy Test"), :pre_exam_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # Prepare for Exam
  # ----------------------------------------------------------------------------------------------------------
  def load_exam
    
    @tab = "mem"
    @sub = "acctest" 
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Accuracy Test"), :pre_exam_path
    
    exam_questions  = Array.new  # reference being tested
    exam_answers    = Array.new	 # exam solution
    exam_submission = Array.new  # users answers
    exam_id         = Array.new  # memverse ID
    
    
    if current_user.memorized >= 10
      
      # Find the memorized verses and pick 10 at random for the test
      exam = Memverse.where(:user_id => current_user.id, :status => "Memorized").random(10)
        
      # Create session variables
      session[:exam_questions]    = exam.map { |mv| mv.id }
      session[:exam_submission]   = exam_submission
      session[:exam_cntr]         = 0
      session[:exam_correct]      = 0    
      session[:exam_answered]     = 0
      session[:exam_length]       = exam.length
      session[:exam_incorrect]    = Array.new
      
      # Start Test
      redirect_to test_exam_path
    else
      flash[:notice] = "You need to memorize 10 verses before you can take the test."
      redirect_to :action => 'index'
    end
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Exam Question
  # ----------------------------------------------------------------------------------------------------------
  def test_exam
    
    @tab = "mem"
    @sub = "acctest"  
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Accuracy Test"), :test_exam_path
    
    if session[:exam_cntr] # The session variables are not set if user comes straight to this page
      
      @question_num = session[:exam_cntr]
      @mv           = Memverse.find(session[:exam_questions][@question_num])
      
    else
      redirect_to :action => 'index'
    end
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Score Accuracy Test
  # ----------------------------------------------------------------------------------------------------------
  def mark_exam
    
    question_num  = session[:exam_cntr] || 1  # Set exam question number to 1 if session variable is nil
    mv            = Memverse.find(session[:exam_questions][question_num])

    answer        = params[:answer].gsub(/\s+/," ").strip if params[:answer]    
    solution      = mv.verse.text.gsub(/\s+/," ").strip
    
    logger.debug("Answer:   #{answer}")
    logger.debug("Solution: #{solution}")
    
    if solution && answer
      
      # ---- TODO: Update this for greater leniency --------------
      if answer.downcase.gsub(/[^a-z ]|\s-|\s—/, '') == solution.downcase.gsub(/[^a-z ]|\s-|\s—/, '')
        flash[:notice] = "Correct"
        session[:exam_correct] += 1
      else
        flash[:notice] = "Incorrect"
        session[:exam_incorrect] << question_num
      end
      # ---- Update this --------------

      # Update score
      session[:exam_answered] += 1
      session[:exam_submission] << Verse.diff(solution, answer)
  
      # Start Next Question
      session[:exam_cntr] += 1
      
      # Stop after questions are finished or if user quits
      if session[:exam_answered] >= session[:exam_length] or params[:commit]=="Exit Exam" 
        redirect_to exam_results_path
      else
        redirect_to test_exam_path
      end
    
    else
      # Probably caused by user using the back button after test is finished
      logger.info("*** User probably hit the back button")
      flash[:notice] = "Exam already completed"
      redirect_to :action => 'index'
    end    
    
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Score Accuracy Exam
  # ----------------------------------------------------------------------------------------------------------
  def exam_results
    
    @tab = "mem"
    @sub = "acctest"    
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Accuracy Test"), :exam_results_path
    
    if session[:exam_answered]
      @correct      = session[:exam_correct]
      @answered     = session[:exam_answered]   
      wrong_answers = session[:exam_incorrect]
      
      # Show where user made mistakes
      @incorrect = Array.new     
      wrong_answers.each do |q_num|
        mv = Memverse.find(session[:exam_questions][q_num])
        solution_set = Hash.new
        solution_set['Ref']       = mv.verse.ref
        solution_set['Txt']       = mv.verse.text
        solution_set['Interval']  = mv.test_interval
        solution_set['Answer']    = session[:exam_submission][q_num]
        @incorrect << solution_set
      end
      
      # Update score
      score = (@correct.to_f / @answered.to_f) * 100
      @old_accuracy = current_user.accuracy
      @new_accuracy = ((@old_accuracy.to_f * 0.75) + (score.to_f * 0.25)).ceil.to_i
      @perfect_score = (@correct == @answered)
          
      # Update user's accuracy grade
      current_user.accuracy = @new_accuracy
      current_user.save
      
      # Clear session variables so that user can't hit refresh and bump up score
      session[:exam_answered] = nil
      session[:exam_cntr]     = nil
     
      # Check for quest completion 
      # spawn_block(:argv => "spawn-accuracy-quest") do
        if q = Quest.where(:url => exam_results_path, :level => current_user.level ).first        
          if score >= q.quantity
            q.check_quest_off(current_user)
            flash.keep[:notice] = "You have completed the accuracy test for this level."
          end 
        end
      # end       
      
    else
      redirect_to :action => 'index'      
    end
  
  end

  # ----------------------------------------------------------------------------------------------------------
  # Test a Difficult Reference
  # ----------------------------------------------------------------------------------------------------------
  def test_ref
    
    @tab = "mem"
    @sub = "refrec"  
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Reference Recall"), :start_ref_test_path
    
    if session[:ref_test_cntr] # The session variables are not set if user comes straight to this page
      @question_num = session[:ref_test_cntr]
      @ref          = session[:ref_test][@question_num]
      @soln         = session[:ref_soln][@question_num]
    else
      redirect_to :action => 'index'
    end
    
  end


  # ----------------------------------------------------------------------------------------------------------
  # Score Reference Test
  # ----------------------------------------------------------------------------------------------------------
  def mark_reftest
    
    # Score Questions
    answer        = params[:answer]
    errorcode, book, chapter, verse = parse_verse(answer) 
    
    question_num  = session[:ref_test_cntr]  
    solution      = session[:ref_soln][question_num] if session[:ref_soln]
    
    # We need to check for alternative solutions to account for identical verses
    alt_soln      = identical_verses( solution )
        
    if solution && session[:reftest_answered]
    
      mv = Memverse.find( session[:ref_id][question_num] )
    
      if (book==solution[0] and chapter==solution[1].to_i and verse==solution[2].to_i) or (book==alt_soln[0] and chapter==alt_soln[1].to_i and verse==alt_soln[2].to_i)
        flash[:notice] = "Perfect!"
        session[:reftest_correct] += 1
        session[:reftest_grade] += 10
        mv.ref_interval   = [(mv.ref_interval * 1.5), 365].min.round
      elsif (book==solution[0] and chapter==solution[1].to_i) or (book==alt_soln[0] and chapter==alt_soln[1].to_i)
        flash[:notice] = "Correct book and chapter. The correct reference is " + solution[0].to_s + " " + solution[1].to_s + ":" + solution[2].to_s
        session[:reftest_incorrect] << question_num
        session[:reftest_grade] += 5
        mv.ref_interval = (mv.ref_interval * 0.7).round
      else 
        session[:reftest_incorrect] << question_num
        flash[:notice] = "Sorry - Incorrect. The correct reference is " + solution[0].to_s + " " + solution[1].to_s + ":" + solution[2].to_s
        mv.ref_interval = (mv.ref_interval * 0.6).round
      end
       
      # Update date for next ref test
      mv.next_ref_test  = Date.today + mv.ref_interval        
      mv.save        
       
      # Update score
      session[:reftest_answered] += 1 if session[:reftest_answered]
      
      # Start Next Question
      session[:ref_test_cntr] += 1
      
      # Stop after questions are finished or if user quits
      if session[:reftest_answered] >= session[:reftest_length] or params[:commit]=="Exit Test"  # TODO: handle case where session variables are Nil
        redirect_to reftest_results_path
      else
        redirect_to test_ref_path
      end
    
    else
      # Probably caused by user using the back button after test is finished
      logger.info("*** User probably hit the back button or returned next day without session variable set up")
      flash[:notice] = "Reference recall test already completed or not initialized"
      redirect_to :action => 'index'
    end    
    
  end
  

  
  # ----------------------------------------------------------------------------------------------------------
  # Score Reference Test
  # ----------------------------------------------------------------------------------------------------------
  def reftest_results
    @tab = "mem"
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Reference Recall"), :reftest_results_path
    if session[:reftest_answered]
      @correct    = session[:reftest_correct]
      @answered   = session[:reftest_answered]
      @incorrect  = session[:reftest_incorrect]
      @grade      = session[:reftest_grade]
      
      # Update user's accuracy grade
      @old_ref_grade = current_user.ref_grade
      @new_ref_grade = ((@old_ref_grade.to_f * 0.75) + (@grade.to_f * 0.25)).ceil.to_i       
      
      current_user.ref_grade = @new_ref_grade
      current_user.save      

      # Clear session variables so that user can't hit refresh and bump up score
      session[:reftest_answered] = nil
      session[:reftest_correct]  = nil
      
      # Check for quest completion 
      # spawn_block(:argv => "spawn-reftest-quest") do
        if q = Quest.where(:url => reftest_results_path, :level => current_user.level ).first
        	if @grade >= q.quantity 
	          q.check_quest_off(current_user)
	          flash.keep[:notice] = "You have completed the reference test for this level."
	        end
        end
      # end        
      
    else
      redirect_to :action => 'index'      
    end
  
  end  
  

  # ----------------------------------------------------------------------------------------------------------
  # Save Entry in Progress Table
  # ----------------------------------------------------------------------------------------------------------
  def save_progress_report
    user_id = params[:user_id]
    u = User.find(user_id)
    unless u.nil?
    	# spawn_block(:argv => "spawn-adjust-load") do
		    u.adjust_work_load
	    # end
	    u.save_progress_report
    end
    render :json => { :saved => true } # TODO: sloppy, we should check whether it actually was saved
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show Progress
  # ----------------------------------------------------------------------------------------------------------
  def show_progress
    @tab = "home" 
    @sub = "progress"   
    
    add_breadcrumb I18n.t('home_menu.My Progress'), :progress_path
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Drilling module
  # ----------------------------------------------------------------------------------------------------------   
  def drill_verse
    
    @tab = "mem" 
    @sub = "practice"  
    
    add_breadcrumb I18n.t("memorize_menu.Memorize"), :test_verse_quick_path
    add_breadcrumb I18n.t('memorize_menu.Practice'), :drill_verse_path
    
    @show_feedback = true
    
    # First check for verses in session queue that need to be tested
    if @mv = get_memverse_from_queue()
      # This verse needs to be memorized
      @verse            = get_memverse(@mv.verse_id)
      @text             = @mv.verse.text
      @current_versenum = @mv.verse.versenum
      @show_feedback    = (@mv.test_interval < 60 or current_user.show_echo)
      # Put memory verse into session
      session[:memverse] = @mv.id  
    else
      # Otherwise, find the verse with the shortest test_interval i.e. a new or difficult verse
      @mv = Memverse.find( :first, 
                          :conditions => ["user_id = ? and last_tested < ?", current_user.id, Date.today], 
                          :order      => "test_interval ASC")
 
      if !@mv.nil? # We've found a verse
                              
        # Are there any verses preceding/succeeding this one? If so, we should test those first    
        if @mv.prev_verse or @mv.next_verse
          # Put verses into session queue and begin with start verse
          # Use "practice" mode to ensure that all verses are drilled
          @mv = put_memverse_cohort_into_queue(@mv, "practice")
        end               
        # Put memory verse into session
        session[:memverse] = @mv.id

        # This verse needs to be memorized
        @verse            = get_memverse(@mv.verse_id)
        @text             = @mv.verse.text
        @current_versenum = @mv.verse.versenum 
        @show_feedback    = (@mv.test_interval < 60 or current_user.show_echo)
      else
        # There are no more verses to be tested today
        flash[:notice] = "You have been through all your memory verses for today."
        @mv             = nil # clear out the loaded memory verse
        redirect_to root_path
      end
       
    end
    
    # --- Load prior verse if available
    if @mv and @mv.prev_verse
      prior_verse       = Memverse.find(@mv.prev_verse).verse
      @prior_text       = prior_verse.text
      @prior_versenum   = prior_verse.versenum
    end
    
    # --- Load upcoming verses ---
    @upcoming_verses = current_user.upcoming_verses(limit = 15, mode = "drills" ) unless mobile_device?
   
  end

  # ----------------------------------------------------------------------------------------------------------
  # Process verse after drill
  # ----------------------------------------------------------------------------------------------------------   
  def mark_drill
    if session[:memverse]
      # Retrieve verse from DB
      mv = Memverse.find( session[:memverse] ) 
      # Mark verse as tested and save
      mv.last_tested = Date.today
      mv.save
      
      redirect_to :action => 'drill_verse' 
    else
      redirect_to :action => 'index'
    end        
  end

    
  # ----------------------------------------------------------------------------------------------------------
  # Score the verse memory test
  # TODO: Need to fix this so that user can't hammer away on a button and keep scoring the last verse
  # ----------------------------------------------------------------------------------------------------------   
  def mark_test
    # Update the interval and efactor
    if params[:commit] and session[:memverse]
      q = params[:commit].slice!(/[0-5]?/).to_i
      
      # Retrieve verse from DB
      mv = Memverse.find( session[:memverse] )
      
      # Execute Supermemo algorithm
      newly_memorized = mv.supermemo(q)

      # Give encouragement if verse transitions from "Learning" to "Memorized"
      if newly_memorized
        flash[:notice] = "Congratulations. You have memorized #{mv.verse.ref}."
        Tweet.create(:news => "#{current_user.name_or_login} memorized #{mv.verse.ref}", :user_id => current_user.id, :importance => 5)
        if current_user.reaching_milestone
          flash[:notice] << " That was your #{current_user.memorized+1}th memorized verse!"
          Tweet.create(:news => "#{current_user.name_or_login} memorized #{current_user.his_or_her} #{current_user.memorized+1}th verse", :user_id => current_user.id, :importance => 3)
        end
        if mv.chapter_memorized?
          flash[:notice] << " You have now memorized all of #{mv.verse.book} #{mv.verse.chapter}. Great job!"
          Tweet.create(:news => "#{current_user.name_or_login} memorized #{mv.verse.book} #{mv.verse.chapter}", :user_id => current_user.id, :importance => 2)          
        end
      end
                
      # We should check to see whether there are any more verses to be memorized and redirect elsewhere
      redirect_to :action => 'test_verse'
    else
      logger.debug("*** Invalid parameters!")
      redirect_to :action => 'index'
    end  
  end    
  
  # ----------------------------------------------------------------------------------------------------------
  # Check for errors in verse test
  # Note: we should remove the 'strip' and whitespace substitution 
  #       on the correct verse once we're sure that all the old verses have been
  #       correctly stripped. Newer verses are stripped when saved
  # ----------------------------------------------------------------------------------------------------------  
  def feedback

    guess   = params[:verseguess] ? url_unescape(params[:verseguess]).gsub(/\s+/," ").strip : ""  # Remove double spaces from guesses    
    correct = params[:correct]    ? url_unescape(params[:correct]).gsub(/\s+/," ").strip    : ""  # The correct verse was stripped, cleaned when first saved
    echo    = (params[:echo] == "true")

    logger.debug("Echo (give feedback) is set to: #{echo}")
    logger.debug("Guess   			: #{guess}")
    logger.debug("Correct 			: #{correct}")
    # logger.debug("Guess encoding 	: #{guess.encoding.name}")  # encoding method only available in Ruby 1.9
    # logger.debug("Correct encoding	: #{correct.encoding.name}")

    @correct  = correct
    @feedback = ""  # find a better way to construct the string
 
    guess_words = guess.split(/\s-\s|\s-|\s/)  # used to include the long dash but there isn't a way you can type a long dash'
    right_words = correct.split
        
    if !right_words.empty?
      # Calculate feedback string
      if echo    
        guess_words.each_index { |i|
          if i < right_words.length # check that guess isn't longer than correct answer
            
            if guess_words[i].downcase.gsub(/[^a-z ]/, '') == right_words[i].downcase.gsub(/[^a-z ]/, '')
              @feedback = @feedback + right_words[i] + " "  
            else
              @feedback = @feedback + "..."
            end
            
            if right_words[i+1] == "-" || right_words[i+1] == "—"
              @feedback = @feedback + right_words[i+1] + " "
              # Remove the dash from the array
              right_words.delete_at(i+1)
            end
            
          end          
        } 
      else
        @feedback = "< Feedback disabled >"        
      end
      
      # Check for complete match       
      @match    = (  guess.downcase.gsub(/[^a-z ]|\s-|\s—/, '') == correct.downcase.gsub(/[^a-z ]|\s-|\s—/, '')  )
    end

    render :partial=>'feedback', :layout=>false
    
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Respond to AJAX request for upcoming verses
  # ----------------------------------------------------------------------------------------------------------  
  def upcoming_verses(limit = 20, mode = "test")
    
    current_mv_id = params[:mv_id]
    
    @upcoming_verses = current_user.upcoming_verses(limit, mode, current_mv_id)
       
    respond_to do |format|
      format.html { render :partial=>'upcoming_verses', :layout=>false }
      format.xml  { render :xml => @upcoming_verses }
      format.json { render :json => @upcoming_verses }
    end
    
  end
  
end

# Books in the Bible: 66
# Books in the Old Testament: 39
# Books in the New Testament: 27
# Shortest book in the Bible: 2 John
# Longest book in the Bible: Psalms
# Chapters in the Bible: 1189
# Chapters in the Old Testament: 929
# Chapters in the New Testament: 260
# Middle chapter of the Bible: Psalm 117
# Shortest chapter in the Bible: Psalm 117
# Longest chapter in the Bible: Psalm 119
# Verses in the Bible: 31,173
# Verses in the Old Testament: 23,214
# Verses in the New Testament: 7,959
# Shortest verse in the Bible: John 11:35
# Longest verse in the Bible: Esther 8:9
# Words in the Bible: 773,692
# Words in the Old Testament: 592,439
# Words in the New Testament: 181,253



