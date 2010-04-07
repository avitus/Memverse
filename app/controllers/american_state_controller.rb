class AmericanStateController < ApplicationController
 
  def show
    @us_state = AmericanState.find(params[:id])
    logger.debug("*** Found US State: #{@us_state.name}")
    @users    = @us_state.users
    logger.debug("*** Found #{@users.size} users from this state")

  end   
  
end
