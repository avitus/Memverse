class ExperimentController < ApplicationController
  def finish
    experiment = params[:experiment]
    ab_finished(experiment)
    render :nothing => true
  end
end