# coding: utf-8

class QuizzesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authorize

  add_breadcrumb "Home", :root_path

  # ----------------------------------------------------------------------------------------------------------
  # /quizzes Main quizzes page
  # ----------------------------------------------------------------------------------------------------------
  def index
    @quizzes = Quiz.all
  end

  # ----------------------------------------------------------------------------------------------------------
  # Participate in live quiz
  # ----------------------------------------------------------------------------------------------------------
  def live
    @quiz = Quiz.find(params[:id])
    unless @quiz.open
      flash[:notice] = "Sorry, but this quiz room is not open."
      redirect_to @quiz
      return false
    end
  end

  # GET /quizzes/1
  # GET /quizzes/1.xml
  def show
    from_time = Time.now
    @quiz           = Quiz.find(params[:id])
    @quizquestions  = @quiz.quiz_questions.order('question_no ASC')

    @mcquestions    = @quizquestions.where(question_type: "mcq")

    respond_to do |format|
      format.html # show.html.erb
      format.pdf  # show.pdf.prawn
      format.xml  { render :xml => @quiz }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Create new quiz
  # ----------------------------------------------------------------------------------------------------------
  def new
    @quiz = Quiz.new
  end

  # GET /quizzes/1/edit
  def edit
    @quiz = Quiz.find(params[:id])
  end

  # POST /quizzes
  # POST /quizzes.xml
  def create

    @quiz       = Quiz.new( quiz_params )
    @quiz.user  = current_user

    respond_to do |format|
      if @quiz.save
        flash[:notice] = 'Quiz was successfully created.'
        format.html { redirect_to(@quiz) }
        format.xml  { render :xml => @quiz, :status => :created, :location => @quiz }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quiz.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quizzes/1
  # PUT /quizzes/1.xml
  def update
    @quiz = Quiz.find(params[:id])

    respond_to do |format|
      if @quiz.update_attributes( quiz_params )
        flash[:notice] = 'Quiz was successfully updated.'
        format.html { redirect_to(@quiz) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quiz.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quizzes/1
  # DELETE /quizzes/1.xml
  def destroy
    @quiz = Quiz.find(params[:id])
    @quiz.destroy

    respond_to do |format|
      format.html { redirect_to(quizzes_url) }
      format.xml  { head :ok }
    end
  end

  # GET /quizzes/search.json
  def search
    query     = params[:query]

    quizzes   = Quiz.where("name LIKE ?", "%#{query}%").limit(20).select("id", "name")

    render json: quizzes
  end

  #----- PRIVATE -------------------------------------
  
  private

  def authorize
    if cannot? :manage, Quiz
      flash[:alert] = "You do not have permission to do that."
      redirect_to root_path and return
    end
  end

  def quiz_params
    params.require(:quiz).permit(:name, :description, :start_time)
  end

end
