class PassagesController < ApplicationController

  before_action :authenticate_user!

  add_breadcrumb "Home", :root_path

  # GET /passages
  # GET /passages.json
  def index

    @tab = "home"
    @sub = "manage"
    add_breadcrumb I18n.t("home_menu.My Verses"), :manage_verses_path

    @passages = current_user.passages.order(:book_index, :chapter, :first_verse)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @passages }
    end
  end

  # All passages due for review
  def due
    @passages = current_user.passages.due.active  # 'active' scope excludes passages where all verses are pending

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @passages }
    end
  end


  # GET /passages/1
  # GET /passages/1.json
  def show
    @passage = Passage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @passage }
    end
  end

  # GET /passages/new
  # GET /passages/new.json
  def new
    @passage = Passage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @passage }
    end
  end

  # GET /passages/1/edit
  def edit
    @passage = Passage.find(params[:id])
  end

  # POST /passages
  # POST /passages.json
  def create
    @passage = Passage.new(params[:passage])

    respond_to do |format|
      if @passage.save
        format.html { redirect_to @passage, notice: 'Passage was successfully created.' }
        format.json { render json: @passage, status: :created, location: @passage }
      else
        format.html { render action: "new" }
        format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /passages/1
  # PUT /passages/1.json
  def update
    @passage = Passage.find(params[:id])

    respond_to do |format|
      if @passage.update_attributes(params[:passage])
        format.html { redirect_to @passage, notice: 'Passage was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @passage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /passages/1
  # DELETE /passages/1.json
  def destroy
    @passage = Passage.find(params[:id])
    @passage.destroy  # Note: this shouldn't be used because it doesn't remove the associated memverses

    respond_to do |format|
      format.html { redirect_to passages_url }
      format.json { head :no_content }
    end
  end
end
