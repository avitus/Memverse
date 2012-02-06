class PopversesController < ApplicationController

  # ----------------------------------------------------------------------------------------------------------
  # List of popular verses (only need to return ref, txt, and verse_id for a given translation)
  # ---------------------------------------------------------------------------------------------------------- 
  def index
    
    @pop_verses = Array.new
    
    translation = params[:tl] || "NIV"   # default to NIV translation
    popverses   = Popverse.order("num_users DESC")
    
    if MAJORS.keys.include?(translation.to_sym)
      # All needed fields are included in Popverse table
      popverses.each do |pv|
        if pv.send(translation.downcase)  # we have the text for that verse in the required translation
          @pop_verses << {:ref => pv.pop_ref, :id => pv.send(translation.downcase), :text => pv.send(translation.downcase + "_text")}
        end
      end
    else
      # Needed to build from Verse model
    end
    
    respond_to do |format|
      format.html
      format.json { render :json => @pop_verses }
    end    

  end

  def show
  end

end
