class VerseWebCheck
  include Sidekiq::Worker

  def perform(id)

    vs = Verse.find_by_id(id)

    if vs 
    	if vs.web_text == vs.database_text
      	vs.update_column(:verified, true)
      	Sidekiq.logger.info "Auto-verified verse with ID: " + id
    	else
    		Sidekiq.logger.info "Verse text did not match web for verse with ID: " + id
    	end
		else
			Sidekiq.logger.warn "Unable to find verse with ID: " + id
		end
  
  end

end # class
