# coding: utf-8

class InfoController < ApplicationController

  # This causes a problem with the menu not showing the active tab
  caches_action :leaderboard, :groupboard, :churchboard, :stateboard, :countryboard, :referralboard, :layout => false, :expires_in => 1.hour
  caches_action :pop_verses, :cache_path => Proc.new { |c| c.params }, :expires_in => 1.day

  add_breadcrumb "Home", :root_path

  # ----------------------------------------------------------------------------------------------------------
  # Memverse tutorial
  # ----------------------------------------------------------------------------------------------------------
  def tutorial
    @tab = "help"
    @sub = "tutorial"

    add_breadcrumb I18n.t('menu.help'), :tutorial_path

    if current_user
      # Check for quest completion
      # spawn_block(:argv => "spawn-tutorial-quest") do
        q = Quest.find_by_url(url_for(:action => 'tutorial', :controller => 'info', :only_path => false))
        if q && current_user.quests.where(:id => q.id).empty?
  		    q.check_quest_off(current_user)
  		    flash.keep[:notice] = "You have completed the task: #{q.task}"
        end
      # end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Supermemo Algorithm
  # ----------------------------------------------------------------------------------------------------------
  def sm_description
    @tab = "help"
    @sub = "smalg"
    add_breadcrumb I18n.t('menu.help'), :tutorial_path
    add_breadcrumb I18n.t('page_titles.supermemo'), :supermemo_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # Video Tutorial
  # ----------------------------------------------------------------------------------------------------------
  def video_tut
    @tab = "help"
  	@sub = "vidtut"
    add_breadcrumb I18n.t('menu.help'), :tutorial_path
    add_breadcrumb I18n.t('learn_menu.Video Tutorial'), '/video_tutorial' #currently unused
  end

  # ----------------------------------------------------------------------------------------------------------
  # Volunteer Info
  # ----------------------------------------------------------------------------------------------------------
  def volunteer
    @tab = "contact"
    @sub = "volunteer"
    add_breadcrumb I18n.t('menu.contact'), :contact_path
    add_breadcrumb I18n.t('contact_menu.Volunteer'), :volunteer_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # Contact and Connect Page
  # ----------------------------------------------------------------------------------------------------------
  def contact
    @tab = "contact"
    @sub = "contact"
    add_breadcrumb I18n.t('menu.contact'), :contact_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # FAQ / Help
  # ----------------------------------------------------------------------------------------------------------
  def faq
    @tab = "help"
    @sub = "faq"
    add_breadcrumb I18n.t('menu.contact'), :contact_path
    add_breadcrumb I18n.t('page_titles.help_support'), :faq_path
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show most popular verses
  # ----------------------------------------------------------------------------------------------------------
  def pop_verses

    add_breadcrumb I18n.t("home_menu.Popular Verses"), :popular_path

    @page       = [params[:page].to_i, 99].min    # page number
    @page_size  = 10                              # number of verses per page

    @vs_list = Popverse.limit( @page_size ).offset( @page*@page_size )
  end

  # ----------------------------------------------------------------------------------------------------------
  # Interactive Database Filter
  # Inputs:
  # Outputs:
  # ----------------------------------------------------------------------------------------------------------
  def pop_verses_by_book
    add_breadcrumb I18n.t("page_titles.pop_verses_by_book"), {:action => "pop_verses_by_book"}
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
    add_breadcrumb I18n.t("home_menu.Popular Verses"), :popular_path
    add_breadcrumb "#{@verse.ref_long}", {:action => "show_vs"}
  end

  # ----------------------------------------------------------------------------------------------------------
  # Leaderboard
  # ----------------------------------------------------------------------------------------------------------
  def leaderboard

    @tab = "leaderboard"
    @sub = "solo"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.Leaderboard"), leaderboard_path

    @leaderboard = User.top_users

  end

  # ----------------------------------------------------------------------------------------------------------
  # Church Leaderboard
  # ----------------------------------------------------------------------------------------------------------
  def churchboard

    @tab = "leaderboard"
    @sub = "church"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.Church Leaderboard"), churchboard_path

    @churchboard = Church.top_churches

  end

  # ----------------------------------------------------------------------------------------------------------
  # Group Leaderboard
  # ----------------------------------------------------------------------------------------------------------
  def groupboard

    @tab = "leaderboard"
    @sub = "group"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.Group Leaderboard"), groupboard_path

    @groupboard = Group.top_groups

  end

  # ----------------------------------------------------------------------------------------------------------
  # US States Leaderboard
  # ----------------------------------------------------------------------------------------------------------
  def stateboard

    @tab = "leaderboard"
    @sub = "us-state"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.State Leaderboard"), stateboard_path

    @stateboard = AmericanState.top_states

  end

  # ----------------------------------------------------------------------------------------------------------
  # Country Leaderboard
  # ----------------------------------------------------------------------------------------------------------
  def countryboard

    @tab = "leaderboard"
    @sub = "country"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.Country Leaderboard"), countryboard_path

    @countryboard = Country.top_countries

  end

  # ----------------------------------------------------------------------------------------------------------
  # Top referrers
  # ----------------------------------------------------------------------------------------------------------
  def referralboard
    @tab = "leaderboard"
    @sub = "referrals"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.Referral Leaderboard"), referralboard_path

    @referralboard = User.top_referrers

    # @referralboard = Rails.cache.fetch("top_referrers", :expires_in => 1.hour) do
    #   User.top_referrers
    # end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Show some nice statistics
  # ----------------------------------------------------------------------------------------------------------
  def memverse_clock
    @tab = "leaderboard"
    @sub = "global"

    add_breadcrumb I18n.t("menu.leaderboard"), leaderboard_path
    add_breadcrumb I18n.t("leader_menu.One Church"), memverse_clock_path

    last_entry        = DailyStats.global.order("entry_date DESC").first

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
    add_breadcrumb I18n.t('page_titles.news_network'), :news_path
    feed_urls	= Array.new
    @feeds 		= Array.new

    # === RSS News feed ===
    # Poached from http://www.robbyonrails.com/articles/2005/05/11/parsing-a-rss-feed
    feed_urls << 'http://feeds.christianitytoday.com/christianitytoday/ctmag'
    feed_urls << 'http://feeds.christianitytoday.com/christianitytoday/mostreads'
    feed_urls << 'http://feeds.feedburner.com/tgcblog'
    feed_urls << 'http://www.christianpost.com/rss/feed/church-ministries/'
    # feed_urls << 'http://www.christianpost.com/services/rss/feed/most-popular'
    # feed_urls << 'http://rss.feedsportal.com/c/32752/f/517092/index.rss'  <-- times out

    feed_urls.each { |fd_url|
	  @feeds[ feed_urls.index(fd_url) ]  = RssReader.posts_for(fd_url, length=5, perform_validation=false)
    }

    @feeds.each { |feed|
      if feed
        feed.each { |post|
          # Strip out links to Digg, StumbleUpon etc.
          post.description = post.description.split("<div")[0]  unless !post.description
          post.description = post.description.split("<img")[0]  unless !post.description
          post.description = post.description.split("<p><a")[0] unless !post.description # Remove links for Gospel Coalition
        }
      end
    }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Memorize
  # ----------------------------------------------------------------------------------------------------------
  def demo_test_verse

    add_breadcrumb "Memverse Demo", demo_path

    params[:verseguess] = ""
    @verse            = "Rom 12:2"
    @text             = "Do not conform any longer to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God's will is — his good, pleasing and perfect will."
    @current_versenum = 2
    @mnemonic         = "D n c a l t t p o t w, b b t b t r o y m. T y w b a t t a a w G w i - h g, p a p w."
    @prior_text       = "Therefore, I urge you, brothers, in view of God's mercy, to offer your bodies as living sacrifices, holy and pleasing to God - this is your spiritual act of worship."
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

  # ----------------------------------------------------------------------------------------------------------
  # Check whether email is available / used during registration
  # ----------------------------------------------------------------------------------------------------------
  def email_available
    @user = User.find_by_email(params[:email])
    if @user
      render :json => {:available => 'false'}
    else
      render :json => {:available => 'true'}
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # STT SETIA page with video and text
  # ----------------------------------------------------------------------------------------------------------
  def stt_setia
  end

  # ----------------------------------------------------------------------------------------------------------
  # Bible Bee flash tool designed by Jonathan Peterson
  # ----------------------------------------------------------------------------------------------------------
  def bible_bee_tool
  end

  private

  def info_params
    params.permit(:page)
  end

end
