# class Api::V1::QuizzesController < Api::V1::ApiController

#   # ----------------------------------------------------------------------------------------------------------
#   # Swagger-Blocks DSL [START]
#   # ----------------------------------------------------------------------------------------------------------
#   include Swagger::Blocks

#   swagger_path '/quizzes/upcoming' do

#     operation :get do

#       key :description, 'Returns the upcoming live quiz'
#       key :operationId, 'findUpcomingQuiz'
#       key :tags, ['quiz']
      
#       security do
#         key :oauth2, ['public read write admin']
#       end

#       response 200 do
#         key :description, 'Quiz response'
#         schema do
#           key :'$ref', :Quiz
#         end
#       end
#       response 401 do
#         key :description, 'Unauthorized response'
#         schema do
#           key :'$ref', :Quiz
#         end
#       end
#       response 400 do
#         key :description, 'Incorrectly formed API request'
#         schema do
#           key :'$ref', :Quiz
#         end
#       end
#       response :default do
#         key :description, 'Unexpected error'
#         schema do
#           key :'$ref', :ErrorModel
#         end
#       end

#     end

#   end

#   # ----------------------------------------------------------------------------------------------------------
#   # Swagger-Docs DSL [END]
#   # ----------------------------------------------------------------------------------------------------------
  
#   # # Scopes
#   # before_action only: [:index, :show, :update, :create, :destroy] do
#   #   doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
#   # end

#   # version 1

#   # # The list of verses is paginated for 5 minutes, the verse itself is cached
#   # # until it's modified (using Efficient Validation)
#   # caches :index, :show, :caches_for => 5.minutes

#   # def index
#   #   quizzes = Quiz.all
#   #   expose quizzes.page( params[:page] )
#   # end

#   # def show
#   #   expose quiz
#   # end

#   # def upcoming
#   # 	expose quiz
#   # end

#   # private

#   # def quiz
#   #   @quiz ||= Quiz.find( params[:id] || 1 )
#   # end

# end
