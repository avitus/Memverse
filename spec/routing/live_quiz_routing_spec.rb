require 'rails_helper'

RSpec.describe "Live Quiz Routes", type: :routing do
  it "routes /live_quiz/:quiz to live_quiz#live_quiz" do
    expect(get: "/live_quiz/1").to route_to(
      controller: "live_quiz",
      action: "live_quiz",
      quiz: "1"
    )
  end

  it "routes /live_quiz to live_quiz#live_quiz" do
    expect(get: "/live_quiz").to route_to(
      controller: "live_quiz",
      action: "live_quiz"
    )
  end
end