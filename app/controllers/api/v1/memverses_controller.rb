class Api::V1::MemversesController < Api::V1::ApiController

  doorkeeper_for :all  # Require access token for all actions

  version 1

  # The list of verses is paginated for 5 minutes, the verse itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :caches_for => 5.minutes

  def index
    expose Memverse.page( params[:page] )
  end

  def show
    expose Memverse.find(params[:id])
  end

end