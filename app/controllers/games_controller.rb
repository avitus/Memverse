class GamesController < ApplicationController
  def verse_scramble
    @page_title = "Verse Scramble"
    
    # Pick a random verse
    @verse = Memverse.where(user_id: current_user.id).sample.verse.text.split
    
  end
end