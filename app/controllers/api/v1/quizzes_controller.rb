class Api::V1::QuizzesController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/quizzes' do

    operation :get do

      key :description, 'Returns a paginated list of quizzes'
      key :operationId, 'listQuizzes'
      key :tags, ['quiz']

      parameter do
        key :name, :page
        key :in, :query
        key :description, 'Page number requested'
        key :required, false
        key :type, :integer
        key :format, :int64
      end

      security do
        key :oauth2, ['public read write admin']
      end

      response 200 do
        key :description, 'Paginated collection of quizzes'
        schema do
          key :'$ref', :QuizCollectionResponse
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

  swagger_path '/quizzes/{id}' do

    operation :get do

      key :description, 'Returns a single quiz by ID'
      key :operationId, 'getQuizById'
      key :tags, ['quiz']

      parameter do
        key :name, :id
        key :in, :path
        key :description, 'Quiz ID'
        key :required, true
        key :type, :integer
        key :format, :int64
      end

      security do
        key :oauth2, ['public read write admin']
      end

      response 200 do
        key :description, 'Single quiz wrapped in response'
        schema do
          key :'$ref', :QuizResponse
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :ErrorModel
        end
      end
      response 404 do
        key :description, 'Quiz not found'
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

  swagger_path '/quizzes/upcoming' do

    operation :get do

      key :description, 'Returns the upcoming live quiz'
      key :operationId, 'findUpcomingQuiz'
      key :tags, ['quiz']
      
      security do
        key :oauth2, ['public read write admin']
      end

      response 200 do
        key :description, 'Single quiz wrapped in response'
        schema do
          key :'$ref', :QuizResponse
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
  before_action only: [:index, :show, :update, :create, :destroy] do
    doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
  end



  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, caches_for: 5.minutes

  def index
    quizzes = Quiz.all
    expose quizzes.page( params[:page] )
  end

  def show
    expose quiz
  end

  def upcoming
  	expose quiz
  end

  private

  def quiz
    @quiz ||= Quiz.find( params[:id] || 1 )
  end

end
