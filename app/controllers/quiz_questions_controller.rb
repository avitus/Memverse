# coding: utf-8

class QuizQuestionsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :access_permission, :except => [:submit, :search, :create]

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
    @quiz           = @quiz_question.quiz

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quiz_question }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Search for related questions based on the supporting reference
  # ----------------------------------------------------------------------------------------------------------
  def search
    supporting_ref = params[:supporting_ref]
    errorcode, bk, ch, vs = parse_verse( supporting_ref )
    uv = Uberverse.where(:book => bk, :chapter => ch, :versenum => vs).first

    if uv
      related_questions = uv.quiz_questions
    else
      related_questions = nil
    end

    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :json => related_questions }
    end
  end

  # GET /quizquestions/new
  # GET /quizquestions/new.xml
  def new
    @quiz_question = QuizQuestion.new
    @quiz          = Quiz.find(params[:quiz] || 1)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quiz_question }
    end
  end

  # GET /quizquestions/submit
  def submit

    @quiz_question = QuizQuestion.new
    @quiz          = Quiz.find(params[:quiz] || 1)

    respond_to do |format|
      format.html # submit.html.erb
    end
  end

  # GET /quizquestions/1/edit
  def edit
    @quiz          = @quiz_question.quiz
  end

  # POST /quizquestions?quiz=1
  # POST /quizquestions?quiz=1.xml
  # This method handles questions submitted by users as well as the questions created by admins
  def create

    # Remove supporting reference string from list of params
    supporting_ref = params[:quiz_question].delete(:supporting_ref)

    @quiz_question = QuizQuestion.new( params[:quiz_question] )

    # Associate supporting verse with question
    errorcode, bk, ch, vs = parse_verse( supporting_ref )
    @quiz_question.supporting_ref = Uberverse.where(:book => bk, :chapter => ch, :versenum => vs).first

    respond_to do |format|
      if @quiz_question.save
        flash[:notice] = 'Quiz question was successfully created.'

        if URI(request.referer).path == '/submit_question'
          link = "<a href=\"#{submit_question_path}\">[Add another question]</a>"
        else
          link = "<a href=\"#{url_for(:action => 'new', :quiz => @quiz_question.quiz_id, :qno => @quiz_question.question_no + 1)}\">[Add another question]</a>"
        end

        flash.now[:notice] << " #{link} "
        format.html { redirect_to quiz_question_path(@quiz_question) }

      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /quizquestions/1
  # PUT /quizquestions/1.xml
  def update

    # Remove supporting reference string from list of params
    supporting_ref = params[:quiz_question].delete(:supporting_ref)

    # Associate supporting verse with question
    errorcode, bk, ch, vs = parse_verse( supporting_ref )
    @quiz_question.supporting_ref = Uberverse.where(:book => bk, :chapter => ch, :versenum => vs).first

    respond_to do |format|
      if @quiz_question.update_attributes(params[:quiz_question])
        flash[:notice] = 'Quiz question was successfully updated.'
        format.html { redirect_to quiz_question_path(@quiz_question) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quiz_question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quizquestions/1
  # DELETE /quizquestions/1.xml
  def destroy
    @quiz_question.destroy

    respond_to do |format|
      format.html { redirect_to(quizzes_url) }
      format.xml  { head :ok }
    end
  end

  private

  # ----------------------------------------------------------------------------------------------------------
  # Check whether user owns quiz question or is an admin
  # ----------------------------------------------------------------------------------------------------------
  def access_permission
    if current_user.admin?
      @quiz_question = QuizQuestion.find( params[:id] )
    else
      @quiz_question = QuizQuestion.find_by_id( params[:id] )
      if !@quiz_question
        flash[:error] = "No question exists with that ID"
        redirect_to root_path
        false
      elsif @quiz_question.user != current_user
        flash[:error] = "You may only access quiz questions that you created."
        redirect_to root_path
        false
      end
    end
  end

end
