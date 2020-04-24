# class Api::V1::FinalVersesController < Api::V1::ApiController

#   # ----------------------------------------------------------------------------------------------------------
#   # Swagger-Blocks DSL [START]
#   # ----------------------------------------------------------------------------------------------------------
#   include Swagger::Blocks

#   swagger_path '/final_verses' do

#     operation :get do
#       key :description, 'Returns final verse for each chapter of the Bible'
#       key :operationId, 'showFinalVerses'
#       key :tags, ['final_verses']
#       security do
#         key :oauth2, ['admin write read public']
#       end
#       response 200 do
#         key :description, 'Final verse response'
#         schema do
#           key :'$ref', :FinalVerse
#         end
#       end
#       response 401 do
#         key :description, 'Unauthorized response'
#         schema do
#           key :'$ref', :FinalVerse
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

#   # before_action only: [:index] do
#   #   doorkeeper_authorize! :admin, :write, :read, :public # allow any of these scopes access (logical OR)
#   # end

#   # version 1

#   # def index
#   #   final_verses = FinalVerse.all
#   #   expose final_verses.page( params[:page] )
#   # end

# end
