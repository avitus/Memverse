require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe "KnowledgeQuiz State Publishing" do
  include ActiveJob::TestHelper

  let!(:quiz) { FactoryBot.create(:quiz, id: 1) }
  let(:quiz_session) { QuizSession.new(1) }

  before(:each) do
    Sidekiq::Testing.fake!

    # Thorough cleanup before each test
    quiz_session.cleanup_quiz_data

    # Clear all quiz locks from both redis instances
    [$redis, Redis.new].each do |r|
      r.keys("*quiz*").each { |k| r.del(k) }
    end

    # Mock PubNub
    allow(PN).to receive(:publish)

    # Create quiz questions
    5.times do |i|
      FactoryBot.create(:quiz_question,
        mc_question: "Test question #{i + 1}?",
        mc_option_a: "Option A",
        mc_option_b: "Option B",
        mc_option_c: "Option C",
        mc_option_d: "Option D",
        mc_answer: "a",
        question_type: 'mcq',
        approval_status: 'Approved',
        last_asked: 1.month.ago
      )
    end

    # Mock environment and sleep
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
    allow_any_instance_of(KnowledgeQuiz).to receive(:sleep).and_return(nil)
  end

  after(:each) do
    # Ensure complete cleanup
    quiz_session.cleanup_quiz_data
    [$redis, Redis.new].each do |r|
      r.keys("*quiz*").each { |k| r.del(k) }
    end
  end

  it "successfully publishes state changes through the quiz lifecycle" do
    worker = KnowledgeQuiz.new
    published_states = []

    # Capture published state changes
    allow($redis).to receive(:publish).and_call_original
    allow($redis).to receive(:publish).with("quiz:1:state", anything) do |channel, data|
      published_states << JSON.parse(data)
    end

    # Run the worker
    worker.perform

    # Verify all state transitions were published
    state_names = published_states.map { |s| s['state'] }
    expect(state_names).to include('preparing', 'ready', 'running')

    # Verify state transition details
    preparing_state = published_states.find { |s| s['state'] == 'preparing' }
    expect(preparing_state).to include(
      'state' => 'preparing',
      'previous_state' => 'waiting',
      'quiz_id' => 1
    )
    expect(preparing_state['timestamp']).to be_present

    ready_state = published_states.find { |s| s['state'] == 'ready' }
    expect(ready_state).to include(
      'state' => 'ready',
      'previous_state' => 'preparing',
      'quiz_id' => 1
    )

    running_state = published_states.find { |s| s['state'] == 'running' }
    expect(running_state).to include(
      'state' => 'running',
      'previous_state' => 'ready',
      'quiz_id' => 1
    )
  end

  it "handles Redis publish failures gracefully" do
    worker = KnowledgeQuiz.new

    # Make publish fail but allow other Redis operations
    allow($redis).to receive(:publish).with("quiz:1:state", anything).and_raise(Redis::ConnectionError)

    # Worker should complete without raising error
    expect { worker.perform }.not_to raise_error

    # Quiz should end in Available state
    expect(quiz_session.get_quiz_status).to eq("Available")
  end

  it "publishes state change method works correctly" do
    worker = KnowledgeQuiz.new
    published_data = nil

    # Capture what gets published
    allow($redis).to receive(:publish).with("quiz:1:state", anything) do |channel, data|
      published_data = JSON.parse(data)
    end

    # Call the publish_state_change method directly
    result = worker.send(:publish_state_change, 'test_state', 'previous_state')

    expect(result).to be true
    expect(published_data).to eq({
      'state' => 'test_state',
      'previous_state' => 'previous_state',
      'quiz_id' => 1,
      'timestamp' => published_data['timestamp'] # Dynamic value
    })
  end
end