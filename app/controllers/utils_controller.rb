# coding: utf-8

class UtilsController < ApplicationController

  newrelic_ignore

  protect_from_forgery prepend: true, except: [:set_verse_text, :verify_verse]
  before_action :authorize

  # ----------------------------------------------------------------------------------------------------------
  # Admin Dashboard
  # ----------------------------------------------------------------------------------------------------------
  def dashboard

    @active_users_this_week = 0
    @active_users_today     = 0

    # Weekly Activity
    one_week_ago = Date.today-7

    @new_users_this_week    = User.where("created_at > ?", one_week_ago).count
    @new_verses_this_week   = Verse.where("created_at > ?", one_week_ago).count
    @new_mvs_this_week      = Memverse.where("created_at > ?", one_week_ago).count
    @active_users_this_week = User.active_this_week.count

    # Daily Activity
    today = Date.today

    @new_users_today    = User.where("created_at > ?", today).count
    @new_verses_today   = Verse.where("created_at > ?", today).count
    @new_mvs_today      = Memverse.where("created_at > ?", today).count
    @active_users_today = User.active_today.count

    # Pending Verification
    @checked_by_users = Verse.where(:verified => false).where("memverses_count > ?", 1).where("checked_by IS NOT NULL").count
    @not_checked_by_users = Verse.where(:verified => false).where("memverses_count > ?", 1).where("checked_by IS NULL").count

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
  # Destroy a tweet
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
      if !u.confirmed_at
        @usage_table["Pending"] += 1
      else
        @usage_table[quantize_mvs(u.memverses.count)] += 1
      end
    }

    @num_users = User.count
  end

  # ----------------------------------------------------------------------------------------------------------
  # Cohort Analysis
  # ----------------------------------------------------------------------------------------------------------
  def cohort_analysis
    # Cohort analysis for users who added at least one verse

    @cohort_table   = Hash.new(0) # users who signed up in a given month
    @activity_table = Hash.new(0) # users who were active in past month

    # Cohort analysis
    User.find_each { |u|
      if u.confirmed_at && u.has_started?  # confirmed_at is nil until user clicks link in email

      	if u.last_activity_date.nil?
      	  Rails.logger.warn("User #{u.name_or_login} has added verses but the last activity date field is not set")
      	else
	        # Churn rate and cohort analysis
	        @cohort_table[ date_label(u.created_at) ] += 1
	        if Date.today - u.last_activity_date <= 30
	          @activity_table[ date_label(u.created_at) ] += 1
	        end
	      end
      end
    }
  end

  # ----------------------------------------------------------------------------------------------------------
  # User Progression by Cohort
  # ----------------------------------------------------------------------------------------------------------
  def user_progression

    @progression_total    = Hash.new(0)
    @progression_active   = Hash.new(0)
    @progression_inactive = Hash.new(0)
    @cohort_active        = 0
    @cohort_inactive      = 0


    @year  = (params[:yr] || Date.today.year).to_i
    @month = (params[:mo] || Date.today.month).to_i

    if @month == 0
      @year -= 1
      @month = 12
    end

    if @month == 13
      @year += 1
      @month = 1
    end


    start_date = Date.new(@year, @month,  1)
    end_date   = Date.new(@year, @month, -1)

    cohort = User.where(:created_at => start_date..end_date)

    @cohort_size = cohort.count

    cohort.each do |u|

      progression = u.cohort_progression  # syntax [:level => '3 - Started', :active => true]

      if progression[:active]
        @progression_total[    progression[:level] ] += 1
        @progression_active[   progression[:level] ] += 1
        @cohort_active += 1
      else
        @progression_total[    progression[:level] ] += 1
        @progression_inactive[ progression[:level] ] += 1
        @cohort_inactive += 1
      end
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # User progress
  # ----------------------------------------------------------------------------------------------------------
  def user_progress
    @user = User.find(params[:id])
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

    Rails.logger.info("===== Updating popular verses table ====")

    # Changing the number of verses returned doesn't buy anything because you have to access entire memory verse table
    pop_mv = Verse.rank_verse_popularity(100)

    Rails.logger.info("===== Deleting old table of popular verses ====")
    # Delete previous table
    Popverse.delete_all

    Rails.logger.info("===== Saving new table with available translations ====")
    pop_mv.each { |x|

      pv = Popverse.new

      pv.pop_ref    = x[0]
      pv.num_users  = x[1]
      errorcode, pv.book, pv.chapter, pv.versenum = parse_verse(pv.pop_ref)

      avail_translations = Verse.where("book = ? and chapter = ? and versenum = ?", pv.book, pv.chapter, pv.versenum)

      avail_translations.each { |vs|

        case vs.translation
          when "NIV" then pv.niv = vs.id
          when "ESV" then pv.esv = vs.id
          when "NAS" then pv.nas = vs.id
          when "NKJ" then pv.nkj = vs.id
          when "KJV" then pv.kjv = vs.id
        end

        case vs.translation
          when "NIV" then pv.niv_text = vs.text
          when "ESV" then pv.esv_text = vs.text
          when "NAS" then pv.nas_text = vs.text
          when "NKJ" then pv.nkj_text = vs.text
          when "KJV" then pv.kjv_text = vs.text
        end
      }

      pv.save

    }

    redirect_to :action => 'show_popverses'
  end


  # ----------------------------------------------------------------------------------------------------------
  # Mass Email - NOTE: only used for test purposes
  # ----------------------------------------------------------------------------------------------------------
  def mass_email
    # Send out an email
    UserMailer.newsletter_email(current_user).deliver
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
  # Show unapproved blog comments
  # ----------------------------------------------------------------------------------------------------------
  def unapproved_comments
    @comments         = Bloggity::BlogComment.where(:approved => false)
    @newest_comments  = Bloggity::BlogComment.where(:approved => true).order("updated_at DESC").limit(10)
    # TODO - figure out what to do with comments from deleted blog posts
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
    u = User.find(2) # This is me
    UserMailer.progression_email_9( u ).deliver
    redirect_to :action => 'show_verses'
  end

  # ----------------------------------------------------------------------------------------------------------
  # Leaderboard
  # ----------------------------------------------------------------------------------------------------------
  def leaderboard
    @page_title = "Memverse Leaderboard"
    @leaderboard = User.top_users  # returns top users sorted by number of verses memorized
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

    @need_verification = Array.new

    @error_reported	= Verse.where(:error_flag => true )

    if params[:checked_by_users] == "false"
      @checked_user = false
    else
      @checked_user = true
    end

    if @checked_user
      unverified			= Verse.where(:verified => false).where("memverses_count > ?", 1).where("checked_by IS NOT NULL").limit(60)
    else
      unverified      = Verse.where(:verified => false).where("memverses_count > ?", 1).where("checked_by IS NULL").limit(60)
    end

    unverified.each { |vs|
      if vs.web_check == true
        vs.verified = true
        vs.save
      else
      	@need_verification << vs
      end
    }


  end

  # ----------------------------------------------------------------------------------------------------------
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------
  def show_popverses
    @vs_list = Popverse.all
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

    # book         = params[:book]
    # chapter      = params[:chapter]
    # verse        = params[:verse]
    # translation  = params[:translation]

    errorcode, book, chapter, verse = parse_verse(params[:verse])

    logger.debug("Bk: #{book}")
    logger.debug("Ch: #{chapter}")
    logger.debug("Vs: #{verse}")

    @vs_list = Verse.find(:all, :conditions => {:book => book, :chapter => chapter.to_i, :versenum => verse.to_i})

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

    @user_list = User.where(login: search_param).limit(5)

    if @user_list.empty?
      @user_list = User.where(email: search_param).limit(5)

    end

    if @user_list.empty?
      @user_list = User.where(name: search_param).limit(5)
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
    @tags = ActsAsTaggableOn::Tag.all
  end

  def show_verses_with_tag

    @mv_list = Array.new
    @vs_list = Array.new

    @tag = ActsAsTaggableOn::Tag.find(params[:id])
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
    render plain: @verse.text
  end


  # ----------------------------------------------------------------------------------------------------------
  # Verify a verse
  # ----------------------------------------------------------------------------------------------------------
  def verify_verse
    @verse = Verse.find(params[:id])
    @verse.verified   = true
    @verse.error_flag = false
    @verse.save
    render plain: "Verified"
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
      render :action => "edit_verse"
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Delete a verse
  # ----------------------------------------------------------------------------------------------------------
  def destroy_verse
    Verse.find(params[:id]).destroy

    # Related memory verses are deleted in before_destroy callback in verse model.
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

    dead_mv.destroy  # remove verse and sort out next and previous pointers

    redirect_to :back
  end


  # ----------------------------------------------------------------------------------------------------------
  # Show all users
  # ----------------------------------------------------------------------------------------------------------
  def show_users

    period = params[:period] || 'Today'
    case period
      when 'Today' then
        @user_list = User.where("created_at > ?", Date.today).order(params[:sort_order])
      when 'Active' then
        @user_list = User.where("last_activity_date = ?", Date.today)
      when 'Pending' then
        @user_list = User.where(:confirmed_at => nil).order(params[:sort_order])
      when 'All' then
        @user_list = User.order(params[:sort_order])
      else
        @user_list = User.where("created_at > ?", Date.today).order(params[:sort_order])
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show all churches
  # ----------------------------------------------------------------------------------------------------------
  def show_churches
    @church_list = Church.order("users_count DESC")
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
    Church.find_each do |c|
      Church.reset_counters( c.id, :users )
    end
    redirect_to :action => 'show_churches'
  end

  # ----------------------------------------------------------------------------------------------------------
  # Update users counter cache for countries
  # TODO: for some reason this occasionally gets out of synch ... not sure why
  # ----------------------------------------------------------------------------------------------------------
  def update_country_users_counter
    Country.reset_column_information
    Country.find_each do |c|
      Country.reset_counters( c.id, :users )
    end
    redirect_to :action => 'show_countries'
  end

  # ----------------------------------------------------------------------------------------------------------
  # Fix corrupted counter cache - does this for a single country
  # ----------------------------------------------------------------------------------------------------------
  def update_country_user_count
    c = Country.find(params[:id])
    Country.reset_counters( c.id, :users )
    redirect_to :action => 'show_countries'
  end

  # ----------------------------------------------------------------------------------------------------------
  # Fix corrupted counter cache - does this for a single state
  # ----------------------------------------------------------------------------------------------------------
  def update_state_user_count
    c = AmericanState.find(params[:id])
    AmericanState.reset_counters( c.id, :users )
    redirect_to :action => 'show_states'
  end

  # ----------------------------------------------------------------------------------------------------------
  # Fix corrupted counter cache - does this for a single church
  # ----------------------------------------------------------------------------------------------------------
  def update_church_user_count
    c = Church.find(params[:id])
    Church.reset_counters( c.id, :users )
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

  def become_user
    sign_in(:user, User.find(params[:id]))
    redirect_to root_url
  end

end

