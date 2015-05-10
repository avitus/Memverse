class Api::V1::VersesController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/verses/{id}' do
    operation :get do
      key :description, 'Returns a single verse'
      key :operationId, 'findVerseById'
      key :tags, ['verse']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID of verse to fetch'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['admin write read public']
      end
      response 200 do
        key :description, 'verse response'
        schema do
          key :'$ref', :Verse
        end
      end
      response 401 do
        key :description, 'unauthorized response'
        schema do
          key :'$ref', :Verse
        end
      end

      response :default do
        key :description, 'unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end
  end


  swagger_path '/verses/lookup' do
    operation :get do
      key :description, 'Lookup a verse by translation, book, chapter, and verse number'
      key :operationId, 'findVerseByTlBkChVs'
      key :tags, ['verse']

      parameter do
        key :name, :tl
        key :in, :query
        key :description, 'Bible translation of required verse'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :bk
        key :in, :query
        key :description, 'Book'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :ch
        key :in, :query
        key :description, 'Chapter'
        key :required, true
        key :type, :string
      end

      parameter do
        key :name, :vs
        key :in, :query
        key :description, 'Verse number'
        key :required, true
        key :type, :string
      end


      response 200 do
        key :description, 'verse response'
        schema do
          key :'$ref', :Verse
        end
      end
      response 401 do
        key :description, 'unauthorized response'
        schema do
          key :'$ref', :Verse
        end
      end

      response :default do
        key :description, 'unexpected error'
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
  before_action only: [:show, :lookup] do
    doorkeeper_authorize! :admin, :write, :read, :public  # Allow all scopes access for now
  end

  version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :caches_for => 15.minutes

  # GET /verses/{ID}
  def show
    expose Verse.find( params[:id] )
  end

  # GET /verses/lookup
  def lookup
    tl = params[:tl] ? params[:tl] : current_resource_owner.translation
    expose Verse.exists_in_db(params[:bk], params[:ch], params[:vs], tl)
  end

end