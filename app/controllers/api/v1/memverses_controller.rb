class Api::V1::MemversesController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/memverses' do
    operation :get do
      key :description, 'Returns memory verses for current user'
      key :operationId, 'showMemverses'
      key :tags, ['memverse']
      parameter do
        key :name, :sort
        key :in, :query
        key :description, 'Field to specify sort order'
        key :required, false
        key :type, :string
      end
      parameter do
        key :name, :page
        key :in, :query
        key :description, 'Page number requested'
        key :required, false
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['read']
      end
      response 200 do
        key :description, 'Memverse response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end

    operation :post do
      key :description, 'Creates a new memory verse'
      key :operationId, 'createMemverse'
      key :produces, ['application/json']
      key :tags, ['memverse']
      parameter do
        key :name, :verse_id
        key :in, :body
        key :description, 'ID of verse to add as a new memory verse for current user'
        key :required, true
        schema do
          key :'$ref', :MemverseInput
        end
      end
      security do
        key :oauth2, ['write admin']
      end
      response 200 do
        key :description, 'Memverse response'
        schema do
          key :'$ref', :Memverse
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


  swagger_path '/memverses/{id}' do

    operation :get do
      key :description, 'Returns a single memory verse'
      key :operationId, 'findMemverseById'
      key :tags, ['memverse']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID of memory verse to fetch'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['read']
      end
      response 200 do
        key :description, 'Memverse response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response 400 do
        key :description, 'Incorrectly formed API request'
        schema do
          key :'$ref', :Memverse
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end

    operation :put do
      key :description, 'Record a rating for a memory verse'
      key :operationId, 'updateMemverseById'
      key :tags, ['memverse']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID of memory verse to update'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      parameter do
        key :name, :q
        key :in, :query
        key :description, 'Rating of verse recall'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['admin write read public']
      end
      response 200 do
        key :description, 'Memverse response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response :default do
        key :description, 'Unexpected error'
        schema do
          key :'$ref', :ErrorModel
        end
      end
    end

    operation :delete do
      key :description, 'Delete a memory verse'
      key :operationId, 'deleteMemverseById'
      key :tags, ['memverse']
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID of memory verse to delete'
        key :required, true
        key :type, :integer
        key :format, :int64
      end
      security do
        key :oauth2, ['admin write read public']
      end
      response 200 do
        key :description, 'Memverse response'
        schema do
          key :'$ref', :Memverse
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :Memverse
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
    mvs = current_resource_owner.memverses
    mvs = params[:sort] ? mvs.order(params[:sort]) : mvs.canonical_sort

    expose mvs.page( params[:page] )
  end

  def show
    expose memverse
  end

  def update
    memverse.supermemo( params[:q].to_i )
    expose memverse
  end

  def create

    vs = Verse.find(params[:id])

    if vs and current_resource_owner

      # We need to lock the user in order to prevent a race condition when two memverses are created simultaneously
      # Without the lock, adding two adjacent verses occasionally results in two separate passages
      ActiveRecord::Base.transaction do

        current_resource_owner.lock! # Hold pessimistic user lock until memverse has been created and all hooks have executed

        if current_resource_owner.has_verse_id?(vs)
          error! :bad_request, metadata: {reason: 'Already added previously'}
        elsif current_resource_owner.has_verse?(vs.book, vs.chapter, vs.versenum)
          error! :bad_request, metadata: {reason: 'Already exists in different translation'}
        else
          # Save verse as a memory verse for user
          begin
            mv = Memverse.create(user: current_resource_owner, verse: vs)
          rescue Exception => e
            Rails.logger.error("=====> [Memverse save error (API)] Exception while saving #{vs.ref} for user #{current_resource_owner.id}: #{e}")
          else
            expose mv, status: :created  # added a new verse
          end
        end

      end # of transaction

    else
      error! :bad_request, metadata: {reason: 'Could not find verse or user'}
    end

  end

  def destroy
    if !memverse
      error! :bad_request, metadata: {reason: 'Could not find memverse'}
    elsif !memverse.destroy
      error! :bad_request, metadata: {reason: 'Memverse could not be destroyed'}
    end
  end

  private

  def memverse
    if current_resource_owner
      @memverse ||= current_resource_owner.memverses.find( params[:id] )
    else
      error! :bad_request, metadata: {reason: 'No current resource owner has been authenticated'}
    end
  end

end