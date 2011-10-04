class AmericanStateController < ApplicationController
  
  add_breadcrumb "Home", :root_path
 
  def show
    @us_state = AmericanState.find(params[:id])
    @users    = @us_state.users.active
    add_breadcrumb I18n.t('leader_menu.State Leaderboard'), stateboard_path
    add_breadcrumb @us_state.name, { :controller => "american_state", :action => "show", :id => params[:id] }
  end   
  
end
