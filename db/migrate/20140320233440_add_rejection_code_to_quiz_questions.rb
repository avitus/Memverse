class AddRejectionCodeToQuizQuestions < ActiveRecord::Migration
  def change
    add_column :quiz_questions, :rejection_code, :string
  end
end
