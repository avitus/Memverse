class HomeController < ApplicationController

  # Current home page, shouldn't be needed in future
  def index
    @users = User.all
  end
end
