class ChurchController < ApplicationController
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Church Leaderboard", :churchboard_path

  def show
    add_breadcrumb @church.try(:name), {:action => "show", :id => params[:id]}
    @church = Church.find(params[:id])
    @users  = @church.users.active.order('memorized DESC')
  end

	def church_params
		params.require(:user).permit(:name, :description)
	end

end
