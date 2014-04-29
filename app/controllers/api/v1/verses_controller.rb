class Api::V1::VersesController < Api::V1::ApiController

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Docs DSL (ALV -- Unable to get Swagger-Docs gem to generate documentation)
  # ----------------------------------------------------------------------------------------------------------
  swagger_controller :verses, "Verses"

  swagger_api :show do
    summary "Show a Verse (based on ID)"
    param :path, :id, :integer, :required, "Verse Id"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  swagger_api :lookup do
    summary "Lookup a Verse (based on reference)"
    param :form, :tl, :string,  :required, "Translation"
    param :form, :bk, :string,  :required, "Book"
    param :form, :ch, :integer, :required, "Chapter"
    param :form, :vs, :integer, :required, "Verse"
    response :unauthorized
    response :not_acceptable
    response :not_found
  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Docs DSL [END]
  # ----------------------------------------------------------------------------------------------------------

  doorkeeper_for :all  # Require access token for all actions

  version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :caches_for => 15.minutes

  def show
    expose Verse.find( params[:id] )
  end

  def lookup
    tl = params[:tl] ? params[:tl] : current_user.translation
    expose Verse.where(:book => params[:bk], :chapter => params[:ch], :versenum => params[:vs], :translation => tl).first
  end

end