class GroupsController < ApplicationController
  
  before_action :authenticate_user!
  
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Group Leaderboard", :groupboard_path
  
  # ----------------------------------------------------------------------------------------------------------
  # Show Group Members
  # ----------------------------------------------------------------------------------------------------------  
  def show
    
    @tab = "profile"
    @sub = "mygroup"
    
    @can_edit = false
    
    if params[:id]
      @group          = Group.find(params[:id])
      @users          = @group.users.order('memorized DESC')    
      @can_edit       = (@group.get_leader! == current_user)
      add_breadcrumb @group.name, {:action => "show", :id => params[:id]}
    elsif current_user.group
      @group          = current_user.group
      @users          = @group.users.order('memorized DESC')
      @can_edit       = (@group.get_leader! == current_user)
      add_breadcrumb I18n.t('profile_menu.My Group'), :mygroup_path
    else
      flash[:notice]  = "You have not yet joined a group. Please join a group in your profile."
      redirect_to update_profile_path
    end

  end    
  
  
  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes( group_params )
        flash[:notice] = 'Your group was successfully updated.'
        format.html { redirect_to(@group) }
        format.json { respond_with_bip(@group) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@group) }
      end
    end
  end 

  def group_params
    params.require(:group).permit(:name, :description, :leader_id)
  end
   
end
