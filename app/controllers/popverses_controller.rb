class PopversesController < ApplicationController

  # ----------------------------------------------------------------------------------------------------------
  # List of popular verses (only need to return ref, txt, and verse_id for a given translation)
  # ---------------------------------------------------------------------------------------------------------- 
  def index
    
    @pop_verses = Array.new
    
    translation = params[:tl] || current_user.translation || "NIV"   # default to NIV translation
    popverses   = Popverse.order("num_users DESC")
        
    if MAJORS.keys.include?(translation.upcase.to_sym)
      # All needed fields are included in Popverse table
      popverses.each do |pv|
        if pv.send(translation.downcase)  # we have the text for that verse in the required translation
          @pop_verses << {:ref => pv.pop_ref, :id => pv.send(translation.downcase), text: pv.send(translation.downcase + "_text")}
        end
      end
    else
      # Need to build from Verse model
      popverses.each do |pv|
        vs = Verse.where(book: pv.book, chapter: pv.chapter, versenum: pv.versenum, translation: translation.upcase).first
        if vs
          @pop_verses << {:ref => vs.ref, :id => vs.id, text: vs.text}
        end
      end
    end
    
    respond_to do |format|
      format.html
      format.json { render :json => @pop_verses }
    end    

  end

end
