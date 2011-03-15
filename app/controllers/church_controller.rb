class ChurchController < ApplicationController
 
  def show
    @church = Church.find(params[:id])
    @users  = @church.users.active
  end   
  
end
