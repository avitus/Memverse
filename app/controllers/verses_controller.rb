class VersesController < ApplicationController
  
  before_filter :login_required, :except => :index
  
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
    @tags  = @verse.tags

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
    @page_title = "Memory Verse Tag Cloud"     
    @tags = Memverse.tag_counts( :order => "name" )
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show verses with tag (in preferred translation if available)
  # ---------------------------------------------------------------------------------------------------------- 
  def show_verses_with_tag
    @tag       = Tag.find_by_name(params[:tag])
    @user_list = Memverse.tagged_with(params[:tag]).map{ |mv| mv.verse.switch_tl(current_user.translation) || mv.verse}.uniq.sort!
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Show verses that need verification ie. more than one user and have never been modified
  # ----------------------------------------------------------------------------------------------------------   
  def check_verses
    
    @need_verification  = Array.new
    tl = current_user.translation
        
    unverified_verses = Verse.find(:all, :conditions => {:verified => 'False', :translation => tl, :checked_by => nil})
    unverified_verses.each { |vs| 
      if vs.memverses.count > 1 and vs.web_check != true
        @need_verification << vs
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