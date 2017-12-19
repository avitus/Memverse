# coding: utf-8

module Parser
  # Parse verse reference -- this function is used a lot
  # @param parse_string [String] e.g. "1 John 2:5-8" or "1 Jn 2:5-8"   
  # @return [Array] e.g. [errorcode, '1 John', 2, 5, 8]
  def parse_passage(parse_string)
    
    if parse_string
      vsref = parse_string.strip
    end
    
    # Check for correct string formatting
    if valid_ref(vsref)
      
      entered_book_name  = vsref.slice!(/([0-3]?\s+)?([a-záéíóúüñ\-]+\s)+/i).rstrip!.titleize
            
      # --- Book name should be translated into English after this point ---
      if I18n.locale == :en
      	book = entered_book_name 
  	  else 
  	  	book = translate_to_english(entered_book_name)
  	  end
	  	  
      book = "Psalms" if book == "Psalm"
      book = "Song of Songs" if book == "Song Of Songs"
  
      if !full_book_name(book) # not a valid book of the Bible
      	logger.info("*** Could not find book: #{book} when parsing string #{parse_string}")
        return 2, book # Error code for invalid book of the bible
      else
        chapter, verse  = vsref.split(/:|vs/)
        if chapter and verse
        	start_vs, end_vs = verse.split(/-/)
        	if end_vs
            return false, full_book_name(book), chapter.slice(/[0-9]+/).to_i, start_vs.slice(/[0-9]+/).to_i, end_vs.slice(/[0-9]+/).to_i     		
        	else
            return false, full_book_name(book), chapter.slice(/[0-9]+/).to_i, start_vs.slice(/[0-9]+/).to_i, nil
          end         
        else
          return 1
        end
      end
    elsif vsref.nil?
      return 3 # Probably no need to return an error here
    else
      return 1 # Error code for incorrectly formatted string 
    end   
  end

  # Lengthens book names in English
  # Input:  'Deut' or 'Deuteronomy'
  # Output: 'Deuteronomy'
  def full_book_name(book)
    if Book.find_by_name(book)
      return Book.find_by_name(book).to_lang(:en).name
    else
      return false
    end
  end

  # Returns true (0) if str is a valid bible reference otherwise nil
  def valid_ref(str)
    return str =~ /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:|(\s?vs\s?))[0-9]+/i
  end
end
