class VerseWebCheck
  include Sidekiq::Worker

  def perform(id)

    vs = Verse.find_by_id(id)

    if vs 
    	if vs.web_text == vs.database_text
      	vs.update_column(:verified, true)
      	Sidekiq.logger.info "Auto-verified verse with ID: " + id.to_s
    	else
    		Sidekiq.logger.info "Verse text did not match web for verse with ID: " + id.to_s
    	end
		else
			Sidekiq.logger.warn "Unable to find verse with ID: " + id.to_s
		end
  
  end

end # class
