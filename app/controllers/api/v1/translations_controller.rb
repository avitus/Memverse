class Api::V1::TranslationsController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/translations' do

    operation :get do
      key :description, 'Returns available Bible translations'
      key :operationId, 'showTranslations'
      key :tags, ['translations']
      security do
        key :oauth2, ['admin write read public']
      end
      response 200 do
        key :description, 'User response'
        schema do
          key :'$ref', :Translation
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :Translation
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

  before_action only: [:index] do
    doorkeeper_authorize! :admin, :write, :read, :public # allow any of these scopes access (logical OR)
  end

  def index
    expose Translation.for_api
  end

end
