# coding: utf-8

# - Add moderators for different translations
# - Add nice, explanatory pop-up boxes using jQuery
# - Add better verse search - allow for missing search parameters to return, for instance, all translations of a given verse
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

  before_filter :authenticate_user!, :except => [:memverse_counter]
  before_action :set_mv, only: [:add_mv_tag, :toggle_mv_status]

  # Added 4/7/10 to prevent invalid authenticity token errors
  # http://ryandaigle.com/articles/2007/9/24/what-s-new-in-edge-rails-better-cross-site-request-forging-prevention
  protect_from_forgery :only => [:create, :update, :destroy]

  prawnto :prawn => { :top_margin     => 50 }
  prawnto :prawn => { :bottom_margin  => 50 }
  prawnto :prawn => { :left_margin    => 50 }
  prawnto :prawn => { :right_margin   => 50 }

  respond_to :html, :pdf, :js, :json

  add_breadcrumb "Home", :root_path

  # ----------------------------------------------------------------------------------------------------------
  # Show memory verses
  # ----------------------------------------------------------------------------------------------------------
  def index

    passage = Passage.find(params[:passage_id])

    @memverses = passage ? passage.memverses.active.includes(:verse).order('verses.versenum') : current_user.memverses

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @memverses }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Home / Start Page
  # ----------------------------------------------------------------------------------------------------------
  def home

    @tab = "home"

    if current_user.needs_quick_start?
      redirect_to :controller => "home", :action => "quick_start" and return
    end

    @due_today	= current_user.due_verses unless mobile_device?
    @due_refs   = current_user.due_refs unless mobile_device?
    @overdue		= current_user.overdue_verses unless mobile_device?

    # Level information
    quests_remaining = current_user.current_uncompleted_quests.length
    @quests_to_next_level = quests_remaining==1 ? "one quest" : quests_remaining.to_s + " quests"

    # Has this user added any verses?
    @user_has_no_verses           = (current_user.learning == 0) && (current_user.memorized == 0)
    # Does this user need more verses?
    @user_has_too_few_verses      = (current_user.learning + current_user.memorized <= 5)

    # Otherwise, show some nice statistics and direct user to memorization page if necessary
    if (!@user_has_no_verses)
      mv = Memverse.where(:user_id => current_user.id).order("next_test ASC").first
      if !mv.nil?
        @user_has_test_today = (mv.next_test <= Date.today)
      end

      # Notification of verses and references that are due for review
      unless flash[:error] or flash[:notice] or !current_user.first_verse_today # Show flash with verses due and workload unless another flash or done with review
        flash.now[:notice] = t('messages.today_msg_html',
                                  :due_today => current_user.due_verses,
                                  :due_refs  => current_user.due_refs,
                                  :time      => current_user.work_load )
      end

    end

    # === Get Recent Tweets ===
    @tweets1 = Tweet.where(:importance => 1..2).limit(12).order("created_at DESC")  # Most important tweets
    @tweets2 = Tweet.where(:importance => 3..4).limit(12).order("created_at DESC")  # Moderate importance

    # === RSS Devotional ===
    @dd = Rails.cache.fetch(["devotion", Date.today.month, Date.today.day], :expires_in => 24.hours) do
      Devotion.where(:name => "Spurgeon Morning", :month => Date.today.month, :day => Date.today.day ).first || Devotion.daily_refresh
    end

    # === Verse of the Day ===
    @votd_txt, @votd_ref, @votd_tl, @votd_id  = verse_of_the_day

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
  # Search for a single memory verse (by reference) for a given user
  # ----------------------------------------------------------------------------------------------------------
  def mv_lookup

    # check that both vs numbers are <= 176 and start < end
    # check that chapter <= 150

    query_chapter = [ params[:ch].to_i, 176].min
    query_vs      = [ params[:vs].to_i, 150].min

    @mv = current_user.memverses
              .includes(:verse)
              .where( 'verses.book'        => params[:bk],
                      'verses.chapter'     => query_chapter,
                      'verses.versenum'    => query_vs )
              .first

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @mv }
      format.json { render :json => @mv }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Search for a passage of memory verses (by reference) for a given user
  # Note: this method only handles true *passages* i.e. not Psalm 1:2 for instance
  # ----------------------------------------------------------------------------------------------------------
  def mv_lookup_passage

    # http://stackoverflow.com/questions/1235863/test-if-a-string-is-basically-an-integer-in-quotes-using-ruby
    if /^\d+$/ === params[:vs_start] and /^\d+$/ === params[:vs_end]  # e.g. Romans 8:2-4

      # check that both vs numbers are <= 176 and start < end
      # check that chapter <= 150

      query_chapter  = [ params[:ch].to_i,       176].min
      query_vs_start = [ params[:vs_start].to_i, 150].min
      query_vs_end   = [ params[:vs_end].to_i,   150].min

      @mvs = current_user.memverses
              .includes(:verse)
              .where( 'verses.book'        => params[:bk],
                      'verses.chapter'     => query_chapter,
                      'verses.versenum'    => query_vs_start..query_vs_end )
              .order( 'verses.versenum')
    else

      query_chapter  = [ params[:ch].to_i,       176].min

      @mvs = current_user.memverses  # e.g. Romans 8
              .includes(:verse)
              .where( 'verses.book'        => params[:bk],
                      'verses.chapter'     => query_chapter )
              .order( 'verses.versenum')

    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @mvs }
      format.json { render :json => @mvs }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Search for user's tagged verses
  # ----------------------------------------------------------------------------------------------------------
  def mv_tag_search

    @verses = current_user.memverses.active.tagged_with(params[:searchParams])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @verses }
      format.json { render :json => @verses }
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
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------
  def pop_verses

    @tab = "home"
    @sub = "popvs"

    add_breadcrumb I18n.t("home_menu.Popular Verses"), :popular_verses_path

    @page       = [params[:page].to_i, 99].min     # page number
    @page_size  = 20                               # number of verses per page

    @vs_list = Popverse.limit( @page_size ).offset( @page*@page_size )
  end

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
      add_breadcrumb @mv.verse.ref_long, {:action => 'show', :id => params[:id] }

      @user_tags  = @mv.tags
      @tags       = @verse.tags
      # @other_tags = @verse.all_user_tags  # TODO: this is a very expensive transaction

      @next_mv = @mv.next_verse || @mv.next_verse_in_user_list
      @prev_mv = @mv.prev_verse || @mv.prev_verse_in_user_list

    # ==== Displaying multiple verses ====
    elsif (!mv_ids.blank?) and (params[:Show])

      @mv_list = Memverse.includes(:verse).find(mv_ids)
      @mv_list.sort! # Sort by book. TODO: Pass parameters from manage_verses and sort by that order...

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

      @mv_list = Memverse.includes(:verse).find(mv_ids)
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
  def add_mv_tag
    new_tag = params[:value].titleize # need to clean this up with hpricot or equivalent

    # Notes on using the acts_as_taggable_on gem
    #
    # 1. Owned tags and regular tags are handled in two different modules in the library
    # 2. The method 'tag_list' only returns tags without owners. The method 'all_tags_list' returns all tags
    # 3. user.tag(mv, :with => 'TagA', :on => :tags) *replaces* any prior tags.
    # 4. mv.tag_list = "tagC, tagD" does not appear to overwrite an existing tag list
    #
    # To clean up tag cloud:  ActsAsTaggableOn::Tagging.where(:taggable_type => 'Verse').delete_all

    if !new_tag.empty?
      tag_list = @mv.all_tags_list.to_s + ", " + new_tag
      current_user.tag(@mv, :with => tag_list, :on => :tags)  # We're doing this for now to track which users are tagging

      @mv.verse.update_tags # Update verse model with most popular tags

      render :text => new_tag
    else
      render :text => "[Enter tag name here]"
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Autocomplete tag
  # ----------------------------------------------------------------------------------------------------------
  def tag_autocomplete
    query = params[:term]
    @suggestions = Array.new

    # loop through Verse tags
    Verse.tag_counts.map(&:name).each { |tag|
      @suggestions << tag if tag[0...query.length].downcase == query.downcase
    }

    render :json => @suggestions.to_json
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
  # Toggle verse from 'Active' to 'Pending' status
  # ----------------------------------------------------------------------------------------------------------
  def toggle_mv_status
    new_status = @mv.toggle_status

    respond_to do |format|
      format.html { render :partial => 'mv_status_toggle', :layout => false }
      format.json { render :json => { :mv_status => new_status} }
    end

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
  # NB: MIRROR ANY CHANGES HERE TO UTILS_CONTROLLER !!!!!!
  # ----------------------------------------------------------------------------------------------------------
  def popular_verses(limit = 8, include_current_user_verses = true)

    pop_verses = Array.new

    # Changing the number of verses returned doesn't buy anything because you have to access entire memory verse table
    pop_mv = Popverse.all

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
  # Add a new memory verse
  # ----------------------------------------------------------------------------------------------------------
  def add_verse
    @tab = "home"
    @sub = "addvs"
    add_breadcrumb I18n.t("home_menu.Add Verse"), :add_verse_path

    @translation  = current_user.translation? ? current_user.translation : "NIV" # fallback on NIV
  end

  # ----------------------------------------------------------------------------------------------------------
  # AJAX Verse Add (Assumes that verse is already in DB)
  # ----------------------------------------------------------------------------------------------------------
  def ajax_add
  	vs = Verse.find(params[:id])

  	if vs and current_user

      # We need to lock the user in order to prevent a race condition when two memverses are created simultaneously
      # Without the lock, adding two adjacent verses occasionally results in two separate passages
      ActiveRecord::Base.transaction do

        current_user.lock! # Hold pessimistic user lock until memverse has been created and all hooks have executed

        if current_user.has_verse_id?(vs)
          msg = "Previously Added"
        elsif current_user.has_verse?(vs.book, vs.chapter, vs.versenum)
          msg = "Added in another translation"
        else
          # Save verse as a memory verse for user
          begin
            Memverse.create(:user_id => current_user.id, :verse_id => vs.id)
          rescue Exception => e
            Rails.logger.error("=====> [Memverse save error] Exception while saving #{vs.ref} for user #{current_user.id}: #{e}")
          else
            msg = "Added"
            render :json => { msg: msg }
            return
          end
        end

      end # of transaction

    else
      msg = "Error"
    end

  	render :json => { msg: msg }

  end

  # ----------------------------------------------------------------------------------------------------------
  # Add an entire chapter
  # ----------------------------------------------------------------------------------------------------------
  def add_chapter

    bk = params[:bk]
    ch = params[:ch]
    tl = params[:tl] || current_user.translation

    # Find all the verses for the chapter
    chapter_verses = Verse.where("book = ? and chapter = ? and translation = ? and versenum not in (?)", bk, ch, tl, 0)

    # Add verses one at a time
    chapter_verses.each do |vs|

      # We need to lock the user in order to prevent a race condition when two memverses are created simultaneously
      # Without the lock, adding two adjacent verses occasionally results in two separate passages
      ActiveRecord::Base.transaction do

        current_user.lock! # hold lock on user for each verse using pessimistic locking at database level

        if current_user.has_verse?(vs.book, vs.chapter, vs.versenum)
          msg = "You already have #{vs.ref} in a different translation"

        else
          # Save verse as a memory verse for user
          begin
            Memverse.create(:user_id => current_user.id, :verse_id => vs.id)
          rescue Exception => e
            Rails.logger.error("=====> [Memverse save error] Exception while saving #{vs.ref} for user #{current_user.id}: #{e}")
          else
            msg = "Added"
          end
        end

      end # of transaction

    end

    render :json => {:msg => "Added Chapter" }

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

    @my_verses = current_user.memverses.includes(:verse, :tags)

    if params[:sort_order].present? && ['next_test', 'next_ref_test'].include?(params[:sort_order])
      # Order: active verses at the top, inactive (pending) at the bottom
      @my_verses = @my_verses.order("status!='Pending' DESC, #{params[:sort_order]}")
    elsif params[:sort_order]
      @my_verses = @my_verses.order(params[:sort_order])
    else
      # default to canonical sort
      @my_verses = @my_verses.order('verses.book_index, verses.chapter, verses.versenum')
    end

    respond_to do |format|
      format.html
      format.pdf { render :layout => false } if params[:format] == 'pdf'
        prawnto :filename => "Memverse.pdf", :prawn => { }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Delete memory verses - used to handle the manage verses form (delete a lot of verses or show selected)
  # ----------------------------------------------------------------------------------------------------------
  def delete_verses

    mv_ids = params[:mv]

    if (!mv_ids.blank?) and (params['Delete'])

      mv_ids.each { |mv_id|

        # We need to lock the user in order to prevent a race condition when multiple verses are deleted simultaneously
        ActiveRecord::Base.transaction do

          current_user.lock! # hold lock on user for each verse using pessimistic locking at database level

          # Remove verse from memorization queue
          mem_queue = session[:mv_queue]
          if !mem_queue.blank?
            mem_queue.delete( mv_id ) # Remove verse from the memorization queue if it is sitting in there
          end

          mv = Memverse.find( mv_id )
          mv.destroy

        end # of transaction

      }

      flash[:notice] = "Memory verses have been deleted."
      redirect_to :action => 'manage_verses'

    elsif (mv_ids.blank?)
      flash[:notice] = "You did not select any verses."
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

    book = full_book_name(book)

    if (!errorcode) # If verse is ok

      @avail_chapters = Array.new

      # Check whether verse is already in DB
      @avail_translations = Verse.where(book: book, chapter: chapter,
                                          versenum: versenum).all

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
  # Select chapter to review
  # ----------------------------------------------------------------------------------------------------------
  def chapter_explanation
    @tab = "mem"
    @sub = "chrev"

    add_breadcrumb I18n.t("menu.review"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Chapter Review"), :pre_chapter_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # Review an entire chapter
  # ----------------------------------------------------------------------------------------------------------
  def test_chapter

    @tab = "mem"
    @sub = "chrev"

    add_breadcrumb I18n.t("menu.review"), :test_verse_quick_path
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

    if @chapter
      @bk_ch        = bk + " " + ch

      bk = "Psalms" if bk == "Psalm"

      # verse could be 0 or 1
      @verse        = current_user.memverses.joins(:verse).
                      where("verses.book = ? and verses.chapter = ?", bk, ch).
                      order("verses.versenum").first.verse.versenum
      @final_verse  = @chapter.length
      @final_verse -= 1 if @verse == 0
    else
      redirect_to pre_chapter_path
    end


  end

  # ----------------------------------------------------------------------------------------------------------
  # Memorize [AJAX]
  # ----------------------------------------------------------------------------------------------------------
  def test_verse_quick

    @tab = "mem"
    @sub = "mem"
    @show_feedback = true

    add_breadcrumb I18n.t("menu.review"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Verses"), :test_verse_quick_path

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
        flash[:notice] = "You should first add a few verses."
        redirect_to :action => 'add_verse' and return
      end
    end

    # --- Load upcoming verses ---
    @upcoming_verses = current_user.upcoming_verses unless mobile_device?

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

    if mv.user == current_user

      # Execute Supermemo algorithm
      newly_memorized = mv.supermemo(q)
      # Log event to Treasure Data
      TD.event.post('memorize_verse', {:user_login => current_user.login, :user_id => current_user.id, :verse_id => mv.verse.id,
                                       :mv_id => mv.id, :mv_interval => mv.test_interval, :q => q, :attempts => mv.attempts })

      # Give encouragement if verse transitions from "Learning" to "Memorized"
      if newly_memorized
        msg = "Congratulations. You have memorized #{mv.verse.ref}."
        current_user.broadcast("memorized #{mv.verse.ref}", 5)

        if current_user.reaching_milestone
          current_user.tweet_milestone

          milestone = current_user.memorized+1

          msg << " That was your #{milestone}th memorized verse!"
        end

        if mv.chapter_memorized?
          msg << " You have now memorized all of #{mv.verse.chapter_name}. Great job!"
          current_user.broadcast("memorized #{mv.verse.chapter_name}", 3)
        end
      end

    else
      msg = "You are attempting to modify a memory verse that belongs to another user."
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
  # Reference Recall Test
  # ----------------------------------------------------------------------------------------------------------
  def test_ref

    @tab = "mem"
    @sub = "refrec"

    add_breadcrumb I18n.t("menu.review"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.References"), :test_ref_path

    # Alert user if they have too few references to be tested on
    if current_user.all_refs # User is being tested on all references
      total_reference_pool = current_user.memverses.active.count
    else # User is only being tested on the first verse of a passage
      total_reference_pool = current_user.memverses.active.passage_start.count
    end

    if total_reference_pool == 0
      flash[:notice] = "You have not yet added any verses."
      redirect_to :action => 'add_verse'

    elsif total_reference_pool == 1
      if current_user.all_refs
        flash[:notice] = "You only have 1 reference to be tested on."
      else
        flash[:notice] = "You only have 1 reference to be tested on because you are only being tested on the first verse of each passage."
      end

    elsif total_reference_pool <= 5
      if current_user.all_refs
        flash[:notice] = "You only have #{total_reference_pool} references to be tested on. There will be a lot of repetition."
      else
        flash[:notice] = "You only have #{total_reference_pool} references to be tested on because you are only reviewing the first verse of each passage."
      end
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns the next reference to be tested - this is a service URL for a js routine
  # ----------------------------------------------------------------------------------------------------------
  def test_next_ref

    # First test references that are due for review
    if current_user.all_refs
      mv       = current_user.memverses.active.ref_due.limit(50).sort_by{ rand }.first
      due_refs = current_user.memverses.active.ref_due.count
    else
      mv       = current_user.memverses.active.passage_start.ref_due.limit(50).sort_by{ rand }.first
      due_refs = current_user.memverses.active.passage_start.ref_due.count
    end

    # If all references are current, test user on the less well-known references
    if !mv
      due_refs = 0
      if current_user.all_refs
        mv = current_user.memverses.active.order("ref_interval ASC").limit(50).sort_by{ rand }.first
      else
        mv = current_user.memverses.active.passage_start.order("ref_interval ASC").limit(50).sort_by{ rand }.first
      end
    end

    render :json => { :due_refs => due_refs, :mv => mv }

  end

  # ----------------------------------------------------------------------------------------------------------
  # Update reference test interval and next reference test date
  # Service URL for a JS routine
  # ----------------------------------------------------------------------------------------------------------
  def score_ref_test

    mv     = Memverse.find( params[:mv] )
    score  = params[:score].to_i

    # Update interval

    if score == 10    # correct
      mv.ref_interval = [(mv.ref_interval * 1.5),
                         mv.user.max_interval.to_i].min.round
    else              # incorrect
      mv.ref_interval = [(mv.ref_interval * 0.6), 1].max.round
    end

    # Update date for next ref test
    mv.next_ref_test = Date.today + mv.ref_interval
    mv.save

    render :json => {:msg => 'Score recorded' }

  end

  # ----------------------------------------------------------------------------------------------------------
  # Accuracy Test - Main page
  # ----------------------------------------------------------------------------------------------------------
  def test_accuracy

    @tab = "mem"
    @sub = "acctest"

    add_breadcrumb I18n.t("menu.review"), :test_verse_quick_path
    add_breadcrumb I18n.t("memorize_menu.Accuracy Test"), :test_accuracy_path

    # Alert user if they have too few verses to be tested on
    # Note: the accuracy test will focus exclusively on memorized verses if the user has at least one verse memorized
    if current_user.memverses.memorized.count >=1
      total_verse_pool = current_user.memverses.memorized.count
      memorized_focus  = true
    else
      total_verse_pool = current_user.memverses.active.count
      memorized_focus  = false
    end

    if total_verse_pool == 0
      flash[:notice] = "You have not yet added any verses."
      redirect_to :action => 'add_verse'

    elsif total_verse_pool == 1
      if memorized_focus
        flash[:notice] = "You only have 1 memorized verse to be tested on."
      else
        flash[:notice] = "You only have 1 verse to be tested on."
      end

    elsif total_verse_pool <= 5
      if memorized_focus
        flash[:notice] = "You only have #{total_verse_pool} memorized verses to be tested on. There will be a lot of repetition."
      else
        flash[:notice] = "You only have #{total_verse_pool} verses to be tested on. There will be a lot of repetition."
      end
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Accuracy Test - get next verse to test
  # ----------------------------------------------------------------------------------------------------------
  def accuracy_test_next

    # The accuracy test will exclusively focus on memorized verses 
    mv = current_user.memverses.memorized.sort_by{ rand }.first  # memorized scope excludes pending verses

    # However, if the user has no memorized verses then the accuracy test will run on the learning verses.
    if !mv
      mv = current_user.memverses.active.sort_by{ rand }.first
    end

    prior_mv = mv && mv.prior_mv  # get prior verse if available

    render :json => { :mv => mv, :prior_mv => prior_mv }

  end

  # ----------------------------------------------------------------------------------------------------------
  # Save Entry in Progress Table
  # ----------------------------------------------------------------------------------------------------------
  def save_progress_report
    user_id = params[:user_id]
    u = User.find(user_id)
    unless u.nil?
	    u.adjust_work_load
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
  # For initially committing verses to memory
  # ----------------------------------------------------------------------------------------------------------
  def learn

    @tab = "learn"
    @sub = "learn"

    @hide_select = true # hide translation dropdown

    add_breadcrumb I18n.t("menu.learn"), :test_verse_quick_path
    add_breadcrumb I18n.t('learn_menu.Learn'), :drill_verse_path

  end

  # ----------------------------------------------------------------------------------------------------------
  # Drilling module
  # ----------------------------------------------------------------------------------------------------------
  def drill_verse

    @tab = "learn"
    @sub = "practice"

    add_breadcrumb I18n.t("menu.learn"), :test_verse_quick_path
    add_breadcrumb I18n.t('learn_menu.Practice'), :drill_verse_path

    @show_feedback = true

    # First check for verses in session queue that need to be tested
    if @mv = get_memverse_from_queue
      # This verse needs to be memorized
      @verse            = get_memverse(@mv.verse_id)
      @text             = @mv.verse.text
      @current_versenum = @mv.verse.versenum
      @show_feedback    = @mv.show_feedback?
      # Put memory verse into session
      session[:memverse] = @mv.id
    else
      # Otherwise, find the verse with the shortest test_interval i.e. a new or difficult verse
      @mv = current_user.memverses.active.where("last_tested < ?", Date.today).
              order("test_interval ASC").first

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
      redirect_to root_path
    end
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

  private

  def set_mv
    @mv = Memverse.find(params[:id])
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



