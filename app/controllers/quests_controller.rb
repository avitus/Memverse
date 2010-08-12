class QuestsController < ApplicationController
  
  before_filter :authorize, :except => [:index, :show ]
  
  # GET /quests
  # GET /quests.xml
  def index
    @quests = Quest.all(:order => 'level')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @quests }
    end
  end

  # GET /quests/1
  # GET /quests/1.xml
  def show
    @quest = Quest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quest }
    end
  end

  # GET /quests/new
  # GET /quests/new.xml
  def new
    @quest = Quest.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quest }
    end
  end

  # GET /quests/1/edit
  def edit
    @quest = Quest.find(params[:id])
  end

  # POST /quests
  # POST /quests.xml
  def create
    @quest = Quest.new(params[:quest])

    respond_to do |format|
      if @quest.save
        flash[:notice] = 'Quest was successfully created.'
        format.html { redirect_to(@quest) }
        format.xml  { render :xml => @quest, :status => :created, :location => @quest }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quest.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quests/1
  # PUT /quests/1.xml
  def update
    @quest = Quest.find(params[:id])

    respond_to do |format|
      if @quest.update_attributes(params[:quest])
        flash[:notice] = 'Quest was successfully updated.'
        format.html { redirect_to(@quest) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quest.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quests/1
  # DELETE /quests/1.xml
  def destroy
    @quest = Quest.find(params[:id])
    @quest.destroy

    respond_to do |format|
      format.html { redirect_to(quests_url) }
      format.xml  { head :ok }
    end
  end
  
  def current_user_quests
    @current_user_quests = current_user.quests
    
    logger.debug("Found #{@current_quests.length} quests for user #{current_user.login}")
    
    render :partial=>'current_user_quests', :layout=>false
  end
  
  def quest_completion_check(u = current_user)
    # TODO: Check for quests that have been completed by user
    # Maybe we want to pass in a specific quest that has been completed
    # There are various different types of objects we can check
    #  - Memverses, chapters, books, psalms, proverbs, tags, invitees (future), url
    # better: obj = {vs, ch, bk, url, disciples, email invites, sessions, blog post}, type = { any, Romans, wisdom, history, ot, nt etc), quantity = {1, 2, 5, 10 etc}
    
  end
end
