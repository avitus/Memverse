class ReadingController < ApplicationController

  def chapter

    @chapter_text = Verse.where(book: params[:bk], chapter: params[:ch], translation: "NIV").order(:versenum).pluck(:text).join(" ")

    respond_to do |format|
      format.html { render text: @chapter_text }
      format.json { render json:  @chapter_text }
    end

  end

end
