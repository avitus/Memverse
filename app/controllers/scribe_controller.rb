# coding: utf-8

class ScribeController < ApplicationController

  before_action :authenticate_user!, :access_permission, :sidenav

  # ----------------------------------------------------------------------------------------------------------
  # Scribe Dashboard
  # ----------------------------------------------------------------------------------------------------------
  def index

    @check = params[:check]

    if @check == 'errors'
      @verses = Verse.where(error_flag: true).limit(30).canonical_sort
    elsif TRANSLATIONS.keys.include? @check.try(:to_sym)
      @verses = Verse.where(translation: @check, verified: false).
                      where("memverses_count > ?", 1).limit(30).canonical_sort
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Show verses needing checked
  # ----------------------------------------------------------------------------------------------------------
  def check

    @check = params[:check]

    if @check == 'errors'
      @verses = Verse.where(error_flag: true).limit(30).canonical_sort
    elsif TRANSLATIONS.keys.include? @check.try(:to_sym)
      @verses = Verse.where(translation: @check, verified: false).
                      where("memverses_count > ?", 1).limit(30).canonical_sort
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Scribe in place power editing (used on scribe verse search page)
  # ----------------------------------------------------------------------------------------------------------
  def edit_verse
    @verse = Verse.find(params[:id])

    @verse.text = params[:value]
    @verse.verified = true
    @verse.error_flag = false
    @verse.checked_by = current_user.login
    @verse.save

    render text: @verse.text
  end

  # ----------------------------------------------------------------------------------------------------------
  # Search verses
  # ----------------------------------------------------------------------------------------------------------
  def search
    @verses = Array.new
  end

  # ----------------------------------------------------------------------------------------------------------
  # Search for verse
  # ----------------------------------------------------------------------------------------------------------
  def search_verse
    errorcode, book, chapter, verse = parse_verse(params[:verse])

    logger.debug("Bk: #{book}")
    logger.debug("Ch: #{chapter}")
    logger.debug("Vs: #{verse}")

    @verses = Verse.where(book: book, chapter: chapter, versenum: verse)

    render :partial => 'search_verse', layout: false
  end

  # ----------------------------------------------------------------------------------------------------------
  # Verify a verse
  # ----------------------------------------------------------------------------------------------------------
  def verify_verse
    @verse = Verse.find(params[:id])
    @verse.update_attributes(verified: true, error_flag: false)

    render :text => "Verified"
  end

  private

  def access_permission
    unless can? :manage, Verse
      flash[:alert] = "You do not have permission to do that."
      redirect_to root_path and return
    end
  end

  def sidenav
    # Error reported count
    @errors = Verse.where(error_flag: true).count

    # Verification stats
    @stats = []

    for trans in TRANSLATIONS.keys
      count = Verse.where("memverses_count > 1").
                    where(verified: false, translation: trans).count

      @stats << [trans.to_s, count, TRANSLATIONS[trans][:name]] if count > 0
    end

    @stats.sort! {|a, b| b[1] <=> a[1]}

    @total = Verse.where("memverses_count > 1 and verified = false").count
  end

end

