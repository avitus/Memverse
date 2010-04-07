class AmericanStateController < ApplicationController
 
  def show
    @us_state = AmericanState.find(params[:id])
    @users    = @us_state.users
  end   
  
end
