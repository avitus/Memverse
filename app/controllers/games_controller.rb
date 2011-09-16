class GamesController < ApplicationController
  def verse_scramble
    @page_title = "Verse Scramble"
    
    # Pick a random verse
    @verse = Memverse.find(:all, :conditions => {:user_id => current_user.id}).rand.verse.text.split
    
  end
end