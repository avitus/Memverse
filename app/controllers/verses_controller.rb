# coding: utf-8
class VersesController < ApplicationController
  
  before_filter :authenticate_user!, :except => :index
  skip_before_filter :verify_authenticity_token, :only => [:set_verse_text, :check_verse]  # ALV: attempt to stop redirects to login page when setting verse text
  
  add_breadcrumb "Home", :root_path
  
  # GET /verses
  # GET /verses.xml
  def index
    @verses = Verse.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @verses }
    end
  end

  # GET /verses/1
  # GET /verses/1.xml
  def show
    @verse = Verse.find(params[:id])
    
    if @verse
      @tags  = @verse.tags
      add_breadcrumb "#{@verse.book} #{@verse.chapter}:#{@verse.versenum}", {:action => 'show', :id => params[:id] }
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @verse }
    end
  end

  # GET /verses/new
  # GET /verses/new.xml
  def new
    @verse = Verse.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @verse }
    end
  end

  # GET /verses/1/edit
  def edit
    @verse = Verse.find(params[:id])
  end

  # POST /verses
  # POST /verses.xml
  def create
    @verse = Verse.new(params[:verse])

    respond_to do |format|
      if @verse.save
        flash[:notice] = 'Verse was successfully created.'
        format.html { redirect_to(@verse) }
        format.xml  { render :xml => @verse, :status => :created, :location => @verse }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @verse.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /verses/1
  # PUT /verses/1.xml
  def update
    @verse = Verse.find(params[:id])

    respond_to do |format|
      if @verse.update_attributes(params[:verse])
        flash[:notice] = 'Verse was successfully updated.'
        format.html { redirect_to(@verse) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @verse.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /verses/1
  # DELETE /verses/1.xml
  def destroy
    @verse = Verse.find(params[:id])
    @verse.destroy

    respond_to do |format|
      format.html { redirect_to(verses_url) }
      format.xml  { head :ok }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Verify that string is in correct verse format
  # ----------------------------------------------------------------------------------------------------------  
  def verify_format
  	vs_str = params[:vs_str].html_safe
  	
  	error_code, bk, ch, vs = parse_verse(vs_str)
  	logger.debug("Parsed verse string #{vs_str}: #{error_code}")
	verse_ok = (error_code == false)
  	render :json => verse_ok
  	
  end

  # ----------------------------------------------------------------------------------------------------------
  # In place editing support
  # ----------------------------------------------------------------------------------------------------------    
  def add_verse_tag
    @verse = Verse.find(params[:id])  # TODO: Should also add tag to the other translations
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
    @tags = Memverse.tag_counts( :order => "name" )
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
  # Verse Search Results
  # ----------------------------------------------------------------------------------------------------------  	
	#   def verse_search_results	    
	# @verse_search_results = Verse.search( params[:search_param] )
	#   respond_to do |format| 
	#     format.html { render :partial => 'verse_search_results', :layout=>false }
	#     format.xml  { render :xml 	=> @verse_search_results }
	#   end	    
	#   end

  # ----------------------------------------------------------------------------------------------------------
  # Verse Search Query page
  # ---------------------------------------------------------------------------------------------------------- 	
  def verse_search
  	@tab = "home"
  	@sub = "searchvs"
    add_breadcrumb I18n.t('home_menu.Search Bible'), :search_verse_path
		@verses = Array.new
		@verses = Verse.search( params[:searchParams] ) if params[:searchParams]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Show verses that need verification ie. more than one user and have never been modified
  # ----------------------------------------------------------------------------------------------------------   
  def check_verses
    
    @need_verification  = Array.new
    tl = current_user.translation
    add_breadcrumb "Check Verses", :check_verses_path
        
    unverified_verses = Verse.where(:verified => false, :translation => tl, :checked_by => nil).where("memverses_count > ?", 1).limit(60)
    unverified_verses.each { |vs| 
      if vs.web_check != true
        @need_verification << vs
      else
        vs.verified = true
        vs.save
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