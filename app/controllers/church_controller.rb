class ChurchController < ApplicationController
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Church Leaderboard", :churchboard_path
  def show
    @church = Church.find(params[:id])
    @users  = @church.users.active
    add_breadcrumb @church.name, {:action => "show", :id => params[:id]}
  end   
  
end
