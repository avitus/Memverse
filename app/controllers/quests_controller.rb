class QuestsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :authorize, :except => [:index, :show, :badge_quests_check ]
  
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

  # ----------------------------------------------------------------------------------------------------------   
  # Show quests that current user is working on
  # ----------------------------------------------------------------------------------------------------------     
  def current_user_quests
    @current_user_quests = current_user.quests    
    render :partial=>'current_user_quests', :layout=>false
  end

  # ----------------------------------------------------------------------------------------------------------   
  # Check whether user has completed any badge quests
  # ----------------------------------------------------------------------------------------------------------   
  def badge_quests_check
    
    @completed_badge_quests = Array.new
    
    badge_quests = Quest.where(:level => nil)  # Get all quests not associated with levels
    badge_quests.each do |q|

      if q.complete?(current_user) && !current_user.quests.include?(q)
        q.check_quest_off(current_user)
        @completed_badge_quests << q
      end

    end
    
    respond_to do |format|
      format.html
      format.json  { render :json => @completed_badge_quests }
    end    
    
  end
  
end
