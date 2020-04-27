# require "rails_helper"

describe "Quiz Question Controller", type: :request do

  before(:each) do
    login_user
    @quiz = FactoryBot.create(:quiz, id: 2, user: @user)  # Quiz with ID=1 is created in seeds.rb
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
    	quiz_id: @quiz,
    	submitted_by: @user,
    	supporting_ref: "Luke 2:2" }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VersesController. Be sure to keep this updated too.
  def valid_session
    {"warden.user.user.key" => session["warden.user.user.key"]}
  end


  it "creates a new Quiz Question and redirects to the Question's page" do
    get "/quiz_question/new"
    expect(response).to render_template(:new)

    # post "/widgets", :params => { :widget => {:name => "My Widget"} }
    post :create, params: {quiz_question: valid_attributes}, session: valid_session

    expect(response).to redirect_to(assigns(:quiz_question))
    follow_redirect!

    expect(response).to render_template(:show)
    expect(response.body).to include("Quiz question was successfully created.")
  end

  it "does not render a different template" do
    get "/widgets/new"
    expect(response).to_not render_template(:show)
  end
end