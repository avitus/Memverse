class GroupController < ApplicationController
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Group Leaderboard", :groupboard_path
  def show
    @group = Group.find(params[:id])
    @users  = @group.users.active
    add_breadcrumb @group.name, {:action => "show", :id => params[:id]}
  end   
  
end
