class PagesController < ApplicationController
  add_breadcrumb "Home", :root_path
  def pendant
    add_breadcrumb "The New Beginnings Pendant", :pendant_path
  end

  def hnb
    add_breadcrumb "The Home of New Beginnings", :hnb_path
  end

end