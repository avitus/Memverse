class Api::V1::TranslationsController < Api::V1::ApiController

  doorkeeper_for :all  # Require access token for all actions

  version 1

  def index
    expose Translation.for_api
  end

  # def show
  #   expose Translation.find(params[:id])
  # end

end
