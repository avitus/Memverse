class ExperimentController < ApplicationController
  def finish
    experiment = params[:experiment]
    ab_finished(experiment)
    head :ok
  end
end