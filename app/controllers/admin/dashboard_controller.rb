class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!
  
  def index
    # Simple landing page for admin tools
  end
  
  private
  
  def authenticate_admin!
    unless current_user&.admin?
      flash[:error] = 'You must be an admin to access this page'
      redirect_to root_path
    end
  end
end