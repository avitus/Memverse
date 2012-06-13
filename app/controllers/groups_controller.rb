class GroupsController < ApplicationController
  
  before_filter :authenticate_user!
  
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Group Leaderboard", :groupboard_path
  
  # ----------------------------------------------------------------------------------------------------------
  # Show Group Members
  # ----------------------------------------------------------------------------------------------------------  
  def show
    
    @tab = "profile"
    @sub = "mygroup"
    
    
    if params[:group]
      add_breadcrumb @group.name, {:action => "show", :id => params[:id]}
      @group          = Group.find(params[:group])
      @users          = @group.users.order('memorized DESC')
    elsif current_user.group
      add_breadcrumb I18n.t('profile_menu.My Group'), :group_path
      @group          = current_user.group
      @users          = @group.users.order('memorized DESC')
    else
      flash[:notice]  = "You have not yet joined a group. Please join a group in your profile."
      redirect_to update_profile_path
    end

  end    
  
  
  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
        format.json { render :json => @group }
      end
    end
  end  
  
end
