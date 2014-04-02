class AddTimestampsToQuizQuestions < ActiveRecord::Migration
  def change
    add_timestamps(:quiz_questions)
  end
end