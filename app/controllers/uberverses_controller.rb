class UberversesController < ApplicationController

  before_action :authorize

  # GET /uberverses
  # GET /uberverses.xml
  def index
    @uberverses = Uberverse.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @uberverses }
    end
  end

  # GET /uberverses/1
  # GET /uberverses/1.xml
  def show
    @uberverse = Uberverse.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @uberverse }
    end
  end

  # GET /uberverses/new
  # GET /uberverses/new.xml
  def new
    @uberverse = Uberverse.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @uberverse }
    end
  end

  # GET /uberverses/1/edit
  def edit
    @uberverse = Uberverse.find(params[:id])
  end

  # POST /uberverses
  # POST /uberverses.xml
  def create
    @uberverse = Uberverse.new(params[:uberverse])

    respond_to do |format|
      if @uberverse.save
        flash[:notice] = 'Uberverse was successfully created.'
        format.html { redirect_to(@uberverse) }
        format.xml  { render :xml => @uberverse, :status => :created, :location => @uberverse }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @uberverse.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /uberverses/1
  # PUT /uberverses/1.xml
  def update
    @uberverse = Uberverse.find(params[:id])

    respond_to do |format|
      if @uberverse.update_attributes(params[:uberverse])
        flash[:notice] = 'Uberverse was successfully updated.'
        format.html { redirect_to(@uberverse) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @uberverse.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /uberverses/1
  # DELETE /uberverses/1.xml
  def destroy
    @uberverse = Uberverse.find(params[:id])
    @uberverse.destroy

    respond_to do |format|
      format.html { redirect_to(uberverses_url) }
      format.xml  { head :ok }
    end
  end

end
