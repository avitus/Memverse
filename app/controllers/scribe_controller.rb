# coding: utf-8

class ScribeController < ApplicationController

  before_filter :authenticate_user!
  before_filter :access_permission

  # ----------------------------------------------------------------------------------------------------------
  # Scribe Dashboard
  # ----------------------------------------------------------------------------------------------------------
  def index

    # TODO: Only load 20 verses at a time. Tell users to refresh to get more.

    @check = params[:check]

    if @check == 'errors'
      @verses = Verse.where(error_flag: true).limit(30).canonical_sort
    elsif TRANSLATIONS.keys.include? @check.try(:to_sym)
      @verses = Verse.where(translation: @check, verified: false).
                      where("memverses_count > ?", 1).limit(30).canonical_sort
    end

    # Error reported stat -- coming soon!
    @errors = Verse.where(error_flag: true).count

    # Verification stats
    @stats = []

    for trans in TRANSLATIONS.keys
      count = Verse.where("memverses_count > 1").
                    where(verified: false, translation: trans).count

      @stats << [trans.to_s, count] if count > 0
    end

    @stats.sort! {|a, b| b[1] <=> a[1]}

    @total = Verse.where("memverses_count > 1 and verified = false").count

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
    current_user.has_role?("scribe")
  end

end

