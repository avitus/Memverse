# coding: utf-8

class QuizquestionsController < ApplicationController
  
  before_filter :authenticate_user!
  
  add_breadcrumb "Home", :root_path
  
  # ----------------------------------------------------------------------------------------------------------   
  # View all questions for a quiz
  # GET /quizquestions?quiz=1
  # ---------------------------------------------------------------------------------------------------------- 
  def index
    if params[:quiz]
      @quiz = Quiz.find(params[:quiz])
    end
    
  end
  
  # GET /quizquestions/1
  # GET /quizquestions/1.xml
  def show
    @question  = QuizQuestion.find(params[:id])
    @quiz      = @question.quiz

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /quizquestions/new
  # GET /quizquestions/new.xml
  def new
    @question = QuizQuestion.new
    @quiz     = Quiz.find(params[:quiz])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /quizquestions/1/edit
  def edit
    @question = QuizQuestion.find(params[:id])
  end

  # POST /quizquestions?quiz=1
  # POST /quizquestions?quiz=1.xml
  def create
    @question = QuizQuestion.new(params[:quiz_question])
    
    respond_to do |format|
      if @question.save
        flash[:notice] = 'Quiz question was successfully created.'
        link = "<a href=\"#{url_for(:action => 'new', :quiz => @question.quiz_id, :qno => @question.question_no + 1)}\">[Add another question]</a>"
        flash.now[:notice] << " #{link} "
        format.html { redirect_to quizquestion_path(@question) }
        format.xml  { render :xml => @question, :status => :created, :location => @question }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quizquestions/1
  # PUT /quizquestions/1.xml
  def update
    @question = QuizQuestion.find(params[:id])

    respond_to do |format|
      if @question.update_attributes(params[:quiz_question])
        flash[:notice] = 'Quiz question was successfully updated.'
        format.html { redirect_to quizquestion_path(@question) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quizquestions/1
  # DELETE /quizquestions/1.xml
  def destroy
    @question = QuizQuestion.find(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to(quizzes_url) }
      format.xml  { head :ok }
    end
  end  
  
  
end
