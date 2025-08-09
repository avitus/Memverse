class AddRejectionCodeToQuizQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :quiz_questions, :rejection_code, :string
  end
end
