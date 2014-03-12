class AddColumnsToQuizQuestions < ActiveRecord::Migration
  def change

    add_column    :quiz_questions, :approval_status, :string, :default => 'Pending'
    add_index     :quiz_questions, :approval_status

  end
end
