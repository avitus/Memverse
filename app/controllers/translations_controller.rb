# coding: utf-8

class TranslationsController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :authorize, :except => [:index]

  # GET /translations
  def index
    @translations = TRANSLATIONS

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @translations }
    end
  end

end