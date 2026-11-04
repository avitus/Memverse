# Records one user's answer to a live quiz question. The caller supplies the
# authenticated user; the score comes from grading the answer here, never from the client.
class QuizAnswerSubmission

  # status is one of :graded, :closed, :duplicate or :unanswered; score is set only when :graded
  Result = Struct.new(:status, :score)

  # @param user [User] The authenticated user answering
  # @param quiz_id [Integer, String] Quiz being played
  # @param question_num [Integer, String] Position of the question in the quiz
  # @param answer [String, nil] Blank when the question timed out unanswered
  # @return [Result]
  def self.call(user:, quiz_id:, question_num:, answer:)
    new(user, quiz_id, question_num.to_i, answer.to_s).call
  end

  def initialize(user, quiz_id, question_num, answer)
    @user = user
    @quiz_session = QuizSession.new(quiz_id)
    @question_num = question_num
    @answer = answer
  end

  # @return [Result]
  def call
    # Everyone who plays appears on the scoreboard, even with no points
    @quiz_session.add_participant(@user.id, @user.name_or_login, @user.login)
    return Result.new(:unanswered, nil) if @answer.blank?

    question = open_question
    return Result.new(:closed, nil) unless question

    score = question.grade_answer(@answer, translation: @user.translation)
    status = @quiz_session.record_answer(@question_num, @user.id, score)
    Result.new(status, status == :graded ? score : nil)
  end

  private

  # The question, or nil if it is not open for answers
  def open_question
    question_id = @quiz_session.open_question_id(@question_num)
    QuizQuestion.find_by(id: question_id) if question_id
  end

end
