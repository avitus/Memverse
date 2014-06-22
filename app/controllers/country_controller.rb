class CountryController < ApplicationController
 
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Country Leaderboard", :countryboard_path

  def show
    @country  = Country.find(params[:id])
    @users    = @country.users.active.order('memorized DESC')
    add_breadcrumb @country.printable_name, {action: "show", id: params[:id]}
  end   
  
end
