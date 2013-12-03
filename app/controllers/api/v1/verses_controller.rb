class Api::V1::VersesController < Api::V1::ApiController

  version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :caches_for => 5.minutes

  def index
    expose Verse.page( params[:page] )
  end

  def show
    expose Verse.find(params[:id])
  end

end