# coding: utf-8

class TranslationsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :authorize, :except => [:index]

  # GET /translations
  def index
    @translations = TRANSLATIONS

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @translations }
    end
  end

end