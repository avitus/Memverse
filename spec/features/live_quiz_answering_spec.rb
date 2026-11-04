require 'rails_helper'
require_relative '../support/live_quiz_helpers'

# Drives the real page in a browser with forgery protection on, as in production. Messages the worker
# would publish over PubNub are handed straight to the page's handler.
RSpec.describe "Live Quiz answering", type: :feature, js: true do
  before(:all) do
    DatabaseCleaner[:active_record].strategy = :truncation, {except: %w[final_verses]}
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  let(:user) { FactoryBot.create(:user, name: "John Doe", login: "johndoe", translation: 'NIV') }
  let(:quiz) { FactoryBot.create(:live_ready_quiz) }
  let(:question) { FactoryBot.create(:quiz_question, :mcq) }
  let(:session) { QuizSession.new(quiz.id) }

  before do
    Rails.application.config.action_dispatch.show_exceptions = true
    sign_in user
    setup_quiz_session_with_sync(quiz.id, "Question 1 in progress", { started_at: Time.current })
    setup_quiz_chat_channel(quiz.id)
    visit_live_quiz_and_wait(quiz)
  end

  after do
    Rails.application.config.action_dispatch.show_exceptions = false
    session.cleanup_quiz_data
  end

  def deliver(message)
    page.execute_script("quizRoom.handleMessage(#{message.to_json})")
  end

  def ask(question_num, time_alloc: 30)
    session.open_question(question_num, question.id, time_alloc)
    deliver(
      meta: 'question', q_id: question.id, q_num: question_num, q_type: 'mcq',
      mc_question: question.mc_question,
      mc_option_a: question.mc_option_a, mc_option_b: question.mc_option_b,
      mc_option_c: question.mc_option_c, mc_option_d: question.mc_option_d,
      time_alloc: time_alloc
    )
    expect(page).to have_css("#question-#{question_num} input#submit-answer")
  end

  def reveal(question_num)
    deliver(meta: 'answer', q_num: question_num, q_type: 'mcq', mc_answer: question.mc_answer)
  end

  def score_on_server
    session.get_scoreboard.find { |entry| entry['id'] == user.id.to_s }&.fetch('score').to_i
  end

  it 'scores a right answer on the server and shows the result, then the answer' do
    ask(1)

    choose('q1_opt_b')
    click_button('Answer!')

    expect(find('#question-1 #q-msg')).to have_text('You answered perfectly')
    expect(score_on_server).to eq(10)
    expect(page).to have_css('#dot-1.green.completed')
    expect(find('#question-1 #q-msg')).not_to have_text('The correct answer was')

    reveal(1)

    expect(find('#question-1 #q-msg')).to have_text('The correct answer was (B)')
    expect(page).to have_css('#question-1 li.correct #q1_opt_b')
  end

  it 'marks a wrong answer and does not give the answer away until it is revealed' do
    ask(1)

    choose('q1_opt_a')
    click_button('Answer!')

    expect(find('#question-1 #q-msg')).to have_text('not correct')
    expect(find('#question-1 #q-msg')).not_to have_text('(B)')
    expect(score_on_server).to eq(0)
    expect(page).to have_css('#dot-1.red.completed')

    reveal(1)

    expect(page).to have_css('#question-1 li.incorrect #q1_opt_a')
    expect(page).to have_css('#question-1 li.correct #q1_opt_b')
  end

  it 'keeps the Answer button when nothing is selected, so the player can still answer' do
    ask(1)

    accept_alert(/choose an answer/i) { click_button('Answer!') }

    expect(page).to have_css('#question-1 input#submit-answer')

    choose('q1_opt_b')
    click_button('Answer!')

    expect(find('#question-1 #q-msg')).to have_text('You answered perfectly')
  end

  it "shows Time's up on the current question and lists the player, past question 1" do
    ask(2, time_alloc: 1)

    expect(find('#question-2 #q-msg')).to have_text("Time's up! No points awarded.")
    expect(page).not_to have_css('#question-2 input#submit-answer')
    expect(find('#question-1 #q-msg', visible: :all).text(:all)).to eq('')

    expect(session.get_scoreboard.map { |entry| entry['id'] }).to include(user.id.to_s)
    expect(score_on_server).to eq(0)
  end
end
