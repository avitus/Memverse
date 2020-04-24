class SermonsController < ApplicationController
  
  before_action :authorize, :except => [:index, :show ]
  
  # GET /sermons
  # GET /sermons.xml
  def index
    @sermons = Sermon.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sermons }
    end
  end

  # GET /sermons/1
  # GET /sermons/1.xml
  def show
    @sermon = Sermon.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sermon }
    end
  end

  # GET /sermons/new
  # GET /sermons/new.xml
  def new
    @sermon = Sermon.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sermon }
    end
  end

  # GET /sermons/1/edit
  def edit
    @sermon = Sermon.find(params[:id])
  end

  # POST /sermons
  # POST /sermons.xml
  def create
    @sermon = Sermon.new(params[:sermon])
    
    errorcode, bk, ch, vs = parse_verse(params[:sermon][:uberverse_id])
    @sermon.uberverse = Uberverse.first(:conditions => {book: bk, chapter: ch, versenum: vs}) || Uberverse.create(book: bk, chapter: ch, versenum: vs)
    
    @sermon.church    = Church.find_by_name(params[:sermon][:church_id]) || Church.create(:name => params[:sermon][:church_id].titleize )
    @sermon.pastor    = Pastor.find_by_name(params[:sermon][:pastor_id]) || Pastor.create(:name => params[:sermon][:pastor_id].titleize )
    @sermon.user      = current_user

    respond_to do |format|
      if @sermon.save
        flash[:notice] = 'Sermon was successfully created.'
        format.html { redirect_to(@sermon) }
        format.xml  { render :xml => @sermon, :status => :created, :location => @sermon }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sermon.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sermons/1
  # PUT /sermons/1.xml
  def update
    @sermon = Sermon.find(params[:id])

    # TODO - need to enable update of church/pastor/verse when editing sermon

    respond_to do |format|
      if @sermon.update_attributes(params[:sermon])
        flash[:notice] = 'Sermon was successfully updated.'
        format.html { redirect_to(@sermon) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sermon.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sermons/1
  # DELETE /sermons/1.xml
  def destroy
    @sermon = Sermon.find(params[:id])
    @sermon.destroy

    respond_to do |format|
      format.html { redirect_to(sermons_url) }
      format.xml  { head :ok }
    end
  end  
  
  
end
