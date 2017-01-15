# coding: utf-8
class VersesController < ApplicationController

  before_filter :authenticate_user!, :except => [:index, :show]
  skip_before_filter :verify_authenticity_token, :only => [:set_verse_text, :check_verse]  # ALV: attempt to stop redirects to login page when setting verse text

  add_breadcrumb "Home", :root_path

  # ----------------------------------------------------------------------------------------------------------
  # GET /verses
  # GET /verses.xml
  # ----------------------------------------------------------------------------------------------------------
  def index
    @verses = Verse.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @verses }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # GET /verses/1
  # GET /verses/1.xml
  # ----------------------------------------------------------------------------------------------------------
  def show
    @verse = Verse.find(params[:id])

    if @verse
      add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path

      add_breadcrumb "#{@verse.book} #{@verse.chapter}:#{@verse.versenum}", {:action => 'show', :id => params[:id] }

      @tags      = @verse.tags
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @verse }
      format.json { render :json => @verse }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # GET /verses/new
  # GET /verses/new.xml
  #
  # Note: Not used because we never explicitly enter a new verse
  # ----------------------------------------------------------------------------------------------------------
  # def new
  #   @verse = Verse.new

  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @verse }
  #   end
  # end

  # ----------------------------------------------------------------------------------------------------------
  # GET /verses/1/edit
  # ----------------------------------------------------------------------------------------------------------
  def edit

    @verse = Verse.find(params[:id])

    add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path
    add_breadcrumb "Edit #{@verse.book} #{@verse.chapter}:#{@verse.versenum}", {:action => 'edit_verse', :id => params[:id] }

  end

  # ----------------------------------------------------------------------------------------------------------
  # POST /verses
  # POST /verses.xml
  # ----------------------------------------------------------------------------------------------------------
  def create
    @verse = Verse.new(params[:verse])

    respond_to do |format|
      if @verse.save
        flash[:notice] = 'Verse was successfully created.'
        format.html { redirect_to(@verse) }
        format.xml  { render :xml => @verse, :status => :created, :location => @verse }
        format.json { render :json => { msg: "Success", verse_id: @verse.id } }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @verse.errors, :status => :unprocessable_entity }
        format.json { render :json => { msg: "Failure", errors: @verse.errors.full_messages } }
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # PUT /verses/1
  # PUT /verses/1.xml
  # ----------------------------------------------------------------------------------------------------------
  def update
    @verse = Verse.find(params[:id])

    respond_to do |format|
      if @verse.locked? and !current_user.admin?
        flash[:notice] = 'This verse has multiple users and can only be edited by a Memverse employee.'
        format.html { redirect_to( @verse ) }
        format.xml  { head :ok }
      elsif @verse.update_attributes(params[:verse])
        flash[:notice] = 'Verse was successfully updated.'
        format.html { redirect_to( @verse ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @verse.errors, :status => :unprocessable_entity }
      end

    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # DELETE /verses/1
  # DELETE /verses/1.xml
  # ----------------------------------------------------------------------------------------------------------
  def destroy
    @verse = Verse.find(params[:id])
    @verse.destroy

    respond_to do |format|
      format.html { redirect_to(verses_url) }
      format.xml  { head :ok }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Verify a verse
  # ----------------------------------------------------------------------------------------------------------
  def toggle_flag
    @verse = Verse.find(params[:id])
    @verse.error_flag = !@verse.error_flag
    @verse.save

    respond_to do |format|
      format.html { render :partial => 'flag_verse', :layout => false }
      format.json { render :json => { :mv_error_flag => @verse.error_flag} }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Find a verse for a user
  # ----------------------------------------------------------------------------------------------------------
  def lookup
    tl = params[:tl] ? params[:tl] : current_user.translation
    @verse = Verse.where(:book => params[:bk], :chapter => params[:ch], :versenum => params[:vs],
                         :translation => tl).first

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @verse }
      format.json { render :json => @verse }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show major translations for a verse
  # ----------------------------------------------------------------------------------------------------------
  def major_tl_lookup

    @verses = Verse.where(:book => params[:bk], :chapter => params[:ch], :versenum => params[:vs],
                          :translation => ['NIV', 'ESV', 'NAS', 'NKJ', 'KJV'])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @verses }
      format.json { render :json => @verses }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Find a passage
  # ----------------------------------------------------------------------------------------------------------
  def lookup_passage

    tl = params[:tl]

    # http://stackoverflow.com/questions/1235863/test-if-a-string-is-basically-an-integer-in-quotes-using-ruby
    if /^\d+$/ === params[:vs_start] and /^\d+$/ === params[:vs_end]  # e.g. Romans 8:2-4

      # check that both vs numbers are <= 176 and start < end
      # check that chapter <= 150

      query_chapter  = [ params[:ch].to_i,       176].min
      query_vs_start = [ params[:vs_start].to_i, 150].min
      query_vs_end   = [ params[:vs_end].to_i,   150].min

      @verses = Verse.where( book:        params[:bk], 
                             chapter:     query_chapter, 
                             versenum:    query_vs_start..query_vs_end, 
                             translation: tl)
                     .order('versenum')
    else

      query_chapter  = [ params[:ch].to_i, 176].min

      @verses = Verse.where( book:    params[:bk], 
                             chapter: query_chapter, 
                             translation: tl)
                     .order('versenum')
    
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @verses }
      format.json { render :json => @verses }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether entire chapter is in DB
  # ----------------------------------------------------------------------------------------------------------
  def chapter_available

    tl = params[:tl]

    query_chapter  = [ params[:ch].to_i, 176].min

    verse = Verse.where(book: params[:bk], 
                        chapter: query_chapter, 
                        versenum: 1, 
                        translation: tl)
                 .first

    if verse && verse.entire_chapter_available
      response = true
    else
      response = false
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => response }
      format.json { render :json => response }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Verify that string is in correct verse format
  # ----------------------------------------------------------------------------------------------------------
  def verify_format
  	vs_str = params[:vs_str].html_safe

  	error_code, bk, ch, vs = parse_verse(vs_str)
    verse_ok = (error_code == false)
  	render :json => verse_ok
  end

  # ----------------------------------------------------------------------------------------------------------
  # In place editing support
  # ----------------------------------------------------------------------------------------------------------
  def add_verse_tag
    @verse = Verse.find(params[:id])  # TODO: Should also add tag to the other translations (?)
    new_tag = params[:value] # need to clean this up with hpricot or equivalent
    @verse.tag_list << new_tag
    @verse.save
    render :text => new_tag
  end

  # ----------------------------------------------------------------------------------------------------------
  # Scrappy little tag cloud
  # ----------------------------------------------------------------------------------------------------------
  def tag_cloud
    @tab = "home"
    @sub = "cloud"
    add_breadcrumb I18n.t('page_titles.tag_cloud'), :tag_cloud_path
    @tags = Verse.tag_counts( :order => "name" )
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show verses with tag (in preferred translation if available)
  # ----------------------------------------------------------------------------------------------------------
  def show_verses_with_tag
    @tab = "home"
    @sub = "cloud"
    add_breadcrumb I18n.t('page_titles.tag_cloud'), :tag_cloud_path
    add_breadcrumb params[:tag], show_verses_with_tag_path(:tag => params[:tag])
    @tag    = ActsAsTaggableOn::Tag.find_by_name(params[:tag])
    @verses = Memverse.tagged_with(params[:tag]).map{ |mv| mv.verse.switch_tl(current_user.translation) || mv.verse}.uniq.sort!
  end

  # ----------------------------------------------------------------------------------------------------------
  # Verse Search Query page
  # ----------------------------------------------------------------------------------------------------------
  def verse_search

    @tab = "home"
  	@sub = "searchvs"
    add_breadcrumb I18n.t('home_menu.Search Bible'), :search_verse_path
		
		@search_text = params[:searchParams]
		@verses = Array.new
		@verses = Verse.search( Riddle::Query.escape(@search_text[0..255]) ) if @search_text
	
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @verses }
      format.json { render :json => @verses }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Show verses that need verification ie. more than one user and have never been modified
  # ----------------------------------------------------------------------------------------------------------
  def check_verses
    tl = current_user.translation
    add_breadcrumb "Check Verses", :check_verses_path

    @need_verification = Verse.where(verified: false, translation: tl, checked_by: nil).where("memverses_count > ?", 1).limit(60)

    # @need_verification  = Array.new

    # unverified_verses = Verse.where(:verified => false, :translation => tl, :checked_by => nil).where("memverses_count > ?", 1).limit(60)
    # unverified_verses.each { |vs|
    #   if vs.web_check != true
    #     @need_verification << vs
    #   else
    #     vs.verified = true
    #     vs.save
    #   end
    # }
  end

  # ----------------------------------------------------------------------------------------------------------
  # In place editing support
  # ----------------------------------------------------------------------------------------------------------
  def set_verse_text
    @verse = Verse.find(params[:id])
    new_text = params[:value] # need to clean this up with hpricot or equivalent
    @verse.text = new_text
    @verse.checked_by = current_user.login
    @verse.save
    render :text => @verse.text
  end

  # ----------------------------------------------------------------------------------------------------------
  # Verify a verse
  # ----------------------------------------------------------------------------------------------------------
  def check_verse
    @verse = Verse.find(params[:id])
    @verse.checked_by = current_user.login
    @verse.save
    render :text => "Checked"
  end

end
