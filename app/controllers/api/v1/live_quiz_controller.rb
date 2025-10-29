class Api::V1::LiveQuizController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  # $.post("/record_score", {   usr_id:       memverseUserID,
  #                             usr_name:     memverseUserName,
  #                             usr_login:    memverseUserLogin,
  #                             question_id:  questionID,
  #                             question_num: questionNum,
  #                             score:        grade.score } );
  swagger_path '/record_score' do

    operation :post do

      key :description, 'Record a user score for a live quiz question'
      key :operationId, 'recordUserScore'
      key :tags, ['quiz']

      parameter do
        key :name, :quiz_id
        key :in, :body
        key :description, 'Quiz ID (defaults to 1 if not provided)'
        key :required, false
        key :type, :integer
        key :format, :int64
      end

      parameter do
        key :name, :usr_id
        key :in, :body
        key :description, 'Memverse user ID'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :usr_name
        key :in, :body
        key :description, 'Memverse user name'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :usr_login
        key :in, :body
        key :description, 'Memverse user login (email address)'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :question_id
        key :in, :body
        key :description, 'Quiz question ID (primary key)'
        key :required, true
        key :type, :integer
        key :format, :int64
      end

      parameter do
        key :name, :question_num
        key :in, :body
        key :description, 'Quiz question number'
        key :required, true
        key :type, :integer
        key :format, :int64
      end

      parameter do
        key :name, :score
        key :in, :body
        key :description, 'The user score (max=10) or "false" to skip scoring'
        key :required, true
        key :type, [:integer, :string]
        key :format, :int64
      end

      security do
        key :oauth2, ['public read write admin']
      end

      response 204 do
        key :description, 'Score successfully recorded'
        schema do
          key :'$ref', :NoContentResponse
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :ErrorModel
        end
      end
      response 400 do
        key :description, 'Incorrectly formed API request'
        schema do
          key :'$ref', :ErrorModel
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

    # Extract parameters
    quiz_id = (params[:quiz_id] || 1).to_i  # Default to knowledge quiz
    usr_id = params[:usr_id].to_i
    usr_name = params[:usr_name]
    usr_login = params[:usr_login]
    qq_id = params[:question_id]  # ID of Quiz Question
    question_num = params[:question_num].to_i
    score = params[:score]        # Score out of 10

    if score != "false" && score.to_i > 0
      # Initialize QuizSession service
      quiz_session = QuizSession.new(quiz_id)

      # Add participant if not already added
      quiz_session.add_participant(usr_id, usr_name, usr_login)

      # Update user's score
      quiz_session.update_score(usr_id, question_num, score.to_i)

      # Update question statistics
      quiz_session.update_question_stats(question_num, qq_id)
    else
      Rails.logger.info("*** Score was submitted as false for #{usr_name}")
    end

    # Return 204 No Content to indicate successful processing
    head :no_content
  end

end
