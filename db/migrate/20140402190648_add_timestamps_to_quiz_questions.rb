class AddTimestampsToQuizQuestions < ActiveRecord::Migration[7.0]
  def change
    add_timestamps(:quiz_questions)
  end
end