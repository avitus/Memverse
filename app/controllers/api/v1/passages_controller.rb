# class Api::V1::PassagesController < Api::V1::ApiController

#   # ----------------------------------------------------------------------------------------------------------
#   # Swagger-Blocks DSL [START]
#   # ----------------------------------------------------------------------------------------------------------
#   include Swagger::Blocks

#   swagger_path '/passages' do
#     operation :get do
#       key :description, 'Returns passages (consecutive memory verses) for current user'
#       key :operationId, 'showPassages'
#       key :tags, ['passage']
#       parameter do
#         key :name, :page
#         key :in, :query
#         key :description, 'Page number requested'
#         key :required, false
#         key :type, :integer
#         key :format, :int64
#       end
#       security do
#         key :oauth2, ['admin read write public']
#       end
#       response 200 do
#         key :description, 'Passage response'
#         schema do
#           key :'$ref', :Passage
#         end
#       end
#       response 401 do
#         key :description, 'Unauthorized response'
#         schema do
#           key :'$ref', :Passage
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

#   swagger_path '/passages/{id}' do

#     operation :get do

#       key :description, 'Returns a single passage by primary key (ID)'
#       key :operationId, 'findPassageById'
#       key :tags, ['passage']
#       parameter do
#         key :name, :id
#         key :in, :path
#         key :description, 'ID of passage to fetch'
#         key :required, true
#         key :type, :integer
#         key :format, :int64
#       end
      
#       security do
#         key :oauth2, ['public read write admin']
#       end

#       response 200 do
#         key :description, 'Passage response'
#         schema do
#           key :'$ref', :Passage
#         end
#       end
#       response 401 do
#         key :description, 'Unauthorized response'
#         schema do
#           key :'$ref', :Passage
#         end
#       end
#       response 400 do
#         key :description, 'Incorrectly formed API request'
#         schema do
#           key :'$ref', :Passage
#         end
#       end
#       response :default do
#         key :description, 'Unexpected error'
#         schema do
#           key :'$ref', :ErrorModel
#         end
#       end

#     end

#     operation :delete do
#       key :description, 'Delete a passage'
#       key :operationId, 'deletePassageById'
#       key :tags, ['passage']
#       parameter do
#         key :name, :id
#         key :in, :path
#         key :description, 'ID of passage to delete'
#         key :required, true
#         key :type, :integer
#         key :format, :int64
#       end
#       security do
#         key :oauth2, ['admin write read public']
#       end
#       response 200 do
#         key :description, 'Passage response'
#         schema do
#           key :'$ref', :Passage
#         end
#       end
#       response 401 do
#         key :description, 'Unauthorized response'
#         schema do
#           key :'$ref', :Passage
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
#   # # ALV: We can't cache because all users access the same URL
#   # # caches :index, :show, :caches_for => 5.minutes

#   # def index
#   #   passages = current_resource_owner.passages.order(:book_index, :chapter, :first_verse)
#   #   expose passages.page( params[:page] )
#   # end

#   # def show
#   #   expose passage
#   # end

#   # # DELETE /passages/1
#   # # DELETE /passages/1.json
#   # def destroy

#   #   if !passage
#   #     error! :bad_request, metadata: {reason: 'Could not find passage'}
#   #   elsif !passage.remove
#   #     error! :bad_request, metadata: {reason: 'Passage could not be destroyed'}
#   #   else
#   #     head :no_content
#   #   end

#   # end

#   # private

#   # def passage
#   #   if current_resource_owner
#   #     @passage ||= current_resource_owner.passages.find( params[:id] )
#   #   else
#   #     error! :bad_request, metadata: {reason: 'No current resource owner has been authenticated'}
#   #   end
#   # end

# end