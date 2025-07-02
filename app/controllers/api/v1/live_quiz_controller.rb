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
        key :name, :usr_id
        key :in, :query
        key :description, 'Memverse user ID'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :usr_name
        key :in, :query
        key :description, 'Memverse user name'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :usr_login
        key :in, :query
        key :description, 'Memverse user login (email address)'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :question_id
        key :in, :query
        key :description, 'Quiz question ID (primary key)'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      
      parameter do
        key :name, :question_num
        key :in, :query
        key :description, 'Quiz question number'
        key :required, true
        key :type, :integer
        key :format, :int64
      end

      parameter do
        key :name, :score
        key :in, :query
        key :description, 'The user score (max=10)'
        key :required, true
        key :type, :integer
        key :format, :int64
      end

      security do
        key :oauth2, ['public read write admin']
      end

      response 200 do
        key :description, 'Quiz response'
      end
      response 401 do
        key :description, 'Unauthorized response'
      end
      response 400 do
        key :description, 'Incorrectly formed API request'
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

    # Redis keys
    usr_id      = "user-" + params[:usr_id].to_s
    q_num       = "qnum-" + params[:question_num].to_s # Question number in Quiz

    usr_name    = params[:usr_name]
    usr_login   = params[:usr_login]
    qq_id       = params[:question_id]  # ID of Quiz Question
    score       = params[:score]        # Score out of 10

    if score != "false"

      # Update user scores. Store the score in Redis store
      $redis.hincrby(usr_id, 'score', score)
      # Capture user's name and login if we don't have them
      $redis.hmset(usr_id, 'name', usr_name, 'login', usr_login, 'id', params[:usr_id].to_s)

      # Update question difficulty
      $redis.hincrby(q_num, 'total_score', score)  # Add user's score to combined score for that question
      $redis.hincrby(q_num, 'answered', 1)         # Increment count for that quiz
      $redis.hsetnx(q_num, 'qq_id', qq_id)         # Store QuizQuestion ID if we don't have it yet

    else

      Rails.logger.info("*** Score was submitted as false for #{usr_name}")

    end

  end



end
