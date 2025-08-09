class AddQuizLengthToQuizzes < ActiveRecord::Migration[7.0]
  def change
    add_column :quizzes, :quiz_length, :integer
  end
end
