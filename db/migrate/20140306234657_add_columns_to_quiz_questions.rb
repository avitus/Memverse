class AddColumnsToQuizQuestions < ActiveRecord::Migration[7.0]
  def change

    add_column    :quiz_questions, :approval_status, :string, :default => 'Pending'
    add_index     :quiz_questions, :approval_status

  end
end
