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

  # doorkeeper_for :all  # Require access token for all actions

  version 1

  def index
    expose Translation.for_api
  end

  # def show
  #   expose Translation.find(params[:id])
  # end

end
