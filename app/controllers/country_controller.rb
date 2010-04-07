class CountryController < ApplicationController
 
  def show
    @country  = Country.find(params[:id])
    @users    = @country.users
  end   
  
end
