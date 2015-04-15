class ApidocsController < < Api::V1::ApiController
	
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'Swagger Memverse'
      key :description, 'Memverse API'
      key :termsOfService, 'http://memverse.com/terms/'
      contact do
        key :name, 'Memverse API Team'
      end
      license do
        key :name, 'MIT'
      end
    end
    tags do
      key :name, 'memverse'
      key :description, 'Memverse operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://swagger.io'
      end
    end
    key :host, 'www.memverse.com'
    key :basePath, '/api'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    VersesController,
    Verse,
    ErrorModel,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end

end