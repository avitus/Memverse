class ExperimentController < ApplicationController
  def finish
    experiment = params[:experiment]
    finished(experiment)
    render nothing: true
  end
end