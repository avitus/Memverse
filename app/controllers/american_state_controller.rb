class AmericanStateController < ApplicationController
  
  add_breadcrumb "Home", :root_path
 
  def show
    add_breadcrumb I18n.t('leader_menu.State Leaderboard'), stateboard_path
    add_breadcrumb @us_state.try(:name), { controller: "american_state", action: "show", id: params[:id] }
        
    @us_state = AmericanState.find(params[:id])
    @users    = @us_state.users.active.order('memorized DESC')
  end   
  
end
