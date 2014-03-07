class AddColumnsToQuizQuestions < ActiveRecord::Migration
  def change

    add_column    :quiz_questions, :approval_status, :string, :default => 'Pending'
    add_index     :quiz_questions, :approval_status

    add_reference :quiz_questions, :user, index: true

  end
end
