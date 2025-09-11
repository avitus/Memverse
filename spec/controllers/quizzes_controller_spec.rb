require 'spec_helper'

describe QuizzesController do
  include FactoryBot::Syntax::Methods

  before(:each) do
    login_quizmaster
  end

  # This should return the minimal set of attributes required to create a valid Quiz.
  # As you add validations to Quiz, be sure to update the return value of this method accordingly.
  def valid_attributes
    {   name: "Bible Bee Quiz 2016",
    	description: "A quiz for the annual Bible Bee",
    	start_time: Time.now + 24.hours }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VersesController. Be sure to keep this updated too.
  def valid_session
    {"warden.user.user.key" => session["warden.user.user.key"]}
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Quiz" do
        expect {
          post :create, params: {quiz: valid_attributes}, session: valid_session
        }.to change(Quiz, :count).by(1)
      end

      it "assigns a newly created Quiz as @Quiz" do
        post :create, params: {quiz: valid_attributes}, session: valid_session
        expect( assigns(:quiz) ).to be_a(Quiz)
        expect( assigns(:quiz) ).to be_persisted
      end

      it "redirects to the created Quiz" do
        post :create, params: {quiz: valid_attributes}, session: valid_session
        expect( response ).to redirect_to(Quiz.last)
      end
    end

  end

  describe "GET show" do
    let(:quiz_with_user) { create(:quiz, user: create(:user)) }
    
    it "assigns the requested quiz as @quiz" do
      get :show, params: { id: quiz_with_user.id }, session: valid_session
      expect(assigns(:quiz)).to eq(quiz_with_user)
    end

    it "renders the show template" do
      get :show, params: { id: quiz_with_user.id }, session: valid_session
      expect(response).to render_template("show")
    end

    it "handles quizzes without associated users gracefully" do
      # Create a quiz with a user, then simulate the user being deleted
      quiz = create(:quiz)
      quiz.user.destroy
      quiz.reload
      
      get :show, params: { id: quiz.id }, session: valid_session
      expect(response).to render_template("show")
      expect(response).to be_successful
    end

    it "assigns quiz questions ordered by question number" do
      quiz = create(:quiz)
      q1 = create(:quiz_question, quiz: quiz, question_no: 2)
      q2 = create(:quiz_question, quiz: quiz, question_no: 1)
      
      get :show, params: { id: quiz.id }, session: valid_session
      
      expect(assigns(:quizquestions)).to eq([q2, q1])
    end
  end


end