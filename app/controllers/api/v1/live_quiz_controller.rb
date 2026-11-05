class Api::V1::LiveQuizController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/record_score' do

    operation :post do

      key :description, 'Submit the answer of the token owner to the open live quiz question. The server grades it and accepts one answer per user per question.'
      key :operationId, 'recordUserScore'
      key :tags, ['quiz']

      parameter do
        key :name, :quiz_id
        key :in, :formData
        key :description, 'Quiz ID (defaults to 1 if not provided)'
        key :required, false
        key :type, :integer
        key :format, :int64
      end

      parameter do
        key :name, :question_num
        key :in, :formData
        key :description, 'Quiz question number'
        key :required, true
        key :type, :integer
        key :format, :int64
      end

      parameter do
        key :name, :answer
        key :in, :formData
        key :description, 'The answer: a, b, c or d for multiple choice, a reference such as John 3:16, or the recited verse. Omit it when the question timed out unanswered.'
        key :required, false
        key :type, :string
      end

      security do
        key :oauth2, ['public read write admin']
      end

      response 200 do
        key :description, 'Submission processed'
        schema do
          key :required, [:status]
          property :status do
            key :type, :string
            key :description, 'graded, closed (question not open), duplicate (already answered) or unanswered (no answer sent)'
          end
          property :score do
            key :type, :integer
            key :format, :int32
            key :description, 'Points out of 10. Present only when status is graded.'
          end
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :ErrorModel
        end
      end
      response 422 do
        key :description, 'The user has not chosen a Bible translation, which grading needs'
        schema do
          key :'$ref', :ApiError
        end
      end
      response 400 do
        key :description, 'question_num is missing or is not a positive integer'
        schema do
          key :'$ref', :ApiError
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end

    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Docs DSL [END]
  # ----------------------------------------------------------------------------------------------------------
  
  # Scopes
  before_action only: [:record_score] do
    doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
  end

  # Nothing to cache in this controller
  # caches :index, :show, :caches_for => 5.minutes

  def record_score
    unless params[:question_num].to_s.match?(/\A[1-9]\d*\z/)
      error!(:bad_request, metadata: { message: 'question_num must be a positive integer' })
      return
    end

    # Recitations are graded against the user's translation, and the website asks for one first
    if current_resource_owner.translation.blank?
      error!(:unprocessable_entity, metadata: { message: 'Please choose a translation before playing the quiz' })
      return
    end

    result = QuizAnswerSubmission.call(
      user: current_resource_owner,
      quiz_id: params[:quiz_id] || 1,  # Default to knowledge quiz
      question_num: params[:question_num],
      answer: params[:answer]
    )

    render json: result.to_h.compact
  end

end
