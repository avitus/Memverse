class Api::V1::PassagesController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/passages' do
    operation :get do
      key :description, 'Returns passages (consecutive memory verses) for current user'
      key :operationId, 'showPassages'
      key :tags, ['passage']
      parameter do
        key :name, :page
        key :in, :query
        key :description, 'Page number requested'
        key :required, false
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['admin read']
      end
      response 200 do
        key :description, 'Passage response'
        schema do
          key :'$ref', :Passage
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :Passage
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

  version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :caches_for => 5.minutes

  def index
    passages = current_resource_owner.passages.order(:book_index, :chapter, :first_verse)
    expose passages.page( params[:page] )
  end

  private

  def passage
    if current_resource_owner
      @passage ||= current_resource_owner.passages.find( params[:id] )
    else
      error! :bad_request, metadata: {reason: 'No current resource owner has been authenticated'}
    end
  end

end