class AmericanStateController < ApplicationController

  add_breadcrumb "Home", :root_path

  def show
    @us_state = AmericanState.friendly.find(params[:id])
    @users    = @us_state.users.active.order('memorized DESC')

    add_breadcrumb I18n.t('leader_menu.State Leaderboard'), stateboard_path
    add_breadcrumb @us_state.try(:name), @us_state
  end

end
