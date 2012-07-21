class AddQuizLengthToQuizzes < ActiveRecord::Migration
  def change
    add_column :quizzes, :quiz_length, :integer
  end
end
