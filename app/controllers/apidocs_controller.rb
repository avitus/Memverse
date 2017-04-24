class ApidocsController < ActionController::Base
  
  include Swagger::Blocks


  class ErrorModel  # Required only for Swagger documentation

    include Swagger::Blocks

    swagger_schema :ErrorModel do
      key :required, [:code, :message]
      property :code do
        key :type, :integer
        key :format, :int32
      end
      property :message do
        key :type, :string
      end
    end

  end

  swagger_root do
    key :swagger, '2.0'

    info do
      key :version, '1.0.0'
      key :title, 'Swagger Memverse'
      key :description, 'Memverse API'
      key :termsOfService, 'https://memverse.com/terms/'
      contact do
        key :name, 'Memverse API Team'
      end
      license do
        key :name, 'MIT'
      end
    end

    tags do
      key :name, 'Memverse'
      key :description, 'Memverse operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://swagger.io'
      end
    end

    security_definition :oauth2 do
      key :type, :oauth2
      # key :authorizationUrl, Rails.env.production? ? 'www.memverse.com/oauth/authorize' : 'http://localhost:3000/oauth/authorize'
      key :authorizationUrl, '/oauth/authorize'
      # key :authorizationUrl, 'http://swagger.io/api/oauth/dialog'
      key :flow, :implicit
      scopes do
        key 'public', 'Read public information'
        key 'read',   'Read your information'
        key 'write',  'Modify your memory verses'
        key 'admin',  'Change settings'
      end
    end

    key :host, Rails.env.production? ? 'www.memverse.com' : 'localhost:3000'
    key :basePath, '/1'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Api::V1::UsersController,
    Api::V1::CredentialsController,
    Api::V1::PassagesController,
    Api::V1::MemversesController,
    Api::V1::VersesController,
    Api::V1::TranslationsController,
    Api::V1::FinalVersesController,
    Api::V1::QuizzesController,
    Api::V1::ProgressReportsController,
    Api::V1::LiveQuizController,
    User,
    Passage,
    Memverse,
    Verse,
    FinalVerse,
    Quiz,
    ProgressReport,
    ErrorModel,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
  
end