describe QuizQuestionsController do

  before(:each) do
    login_user
    @quiz = FactoryBot.create(:quiz, id: 1)
  end

  # This should return the minimal set of attributes required to create a valid
  # Quiz Questions. As you add validations to Quiz Questions, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    { approval_status: "Pending",
    	mc_answer: "C",
    	mc_option_a: "Jerusalem",
    	mc_option_b: "Nazareth",
    	mc_option_c: "Bethlehem",
    	mc_option_d: "Rome",
    	mc_question: "Where was Jesus Christ born?",
    	mcq_category: "Disciples & Apostles",
    	question_no: "1",
    	question_type: "mcq",
    	quiz_id: @quiz.id,
    	submitted_by: @user.id,
    	supporting_ref: "Luke 2:2" }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VersesController. Be sure to keep this updated too.
  def valid_session
    {"warden.user.user.key" => session["warden.user.user.key"]}
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new QuizQuestion" do
        expect {
          post :create, params: {quiz_question: valid_attributes}, session: valid_session
        }.to change(QuizQuestion, :count).by(1)
      end

      it "assigns a newly created QuizQuestions as @QuizQuestion" do
        post :create, params: {quiz_question: valid_attributes}, session: valid_session
        expect( assigns(:quiz_question) ).to be_a(QuizQuestion)
        expect( assigns(:quiz_question) ).to be_persisted
      end

      it "redirects to the created Verse" do
        post :create, params: {quiz_question: valid_attributes}, session: valid_session
        expect( response ).to redirect_to(QuizQuestion.last)
      end
    end

  end


end