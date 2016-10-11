class Api::V1::ProgressReportsController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_path '/progress_reports' do

    operation :get do
      key :description, 'Returns progress data for user'
      key :operationId, 'showUserProgress'
      key :tags, ['progress']
      security do
        key :oauth2, ['admin write read public']
      end
      response 200 do
        key :description, 'User progress response'
        schema do
          key :'$ref', :ProgressReport
        end
      end
      response 401 do
        key :description, 'Unauthorized response'
        schema do
          key :'$ref', :ProgressReport
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

  version 1

  def index
    progress = current_resource_owner.progress_reports
    expose progress.page( params[:page] )
  end

end
