# coding: utf-8
require "juggernaut"  # needed for chat channels
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem

  helper :all # include all helpers, all the time
  protect_from_forgery
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
 
  helper Ziya::HtmlHelpers::Charts
  helper Ziya::YamlHelpers::Charts
  
  before_filter :set_locale, :prepare_for_mobile  



  # ----------------------------------------------------------------------------------------------------------
  # Chat client functionality
  # ----------------------------------------------------------------------------------------------------------    

	def send_message
	  render_text "<li>" + params[:msg_body] + "</li>"
	  Juggernaut.publish("/chats", parse_chat_message(params[:msg_body], "Prabhat"))
	end
	    
	def parse_chat_message(msg, user)
	  return "#{user} says: #{msg}"
	end


  # ----------------------------------------------------------------------------------------------------------
  # Admin Authorization
  # ----------------------------------------------------------------------------------------------------------    
  helper_method :admin?    
  protected  
  def admin?  
    current_user && current_user.has_role?('admin')  
  end    
   
  def authorize  
    unless admin?  
      flash[:error] = "Unauthorized access."
      redirect_to home_path  
      false  
    end  
  end    
   
   
  # ----------------------------------------------------------------------------------------------------------
  # Localization
  # ---------------------------------------------------------------------------------------------------------- 
  def set_locale 
    # if params[:locale] is nil then I18n.default_locale will be used
    if current_user  
      I18n.locale = case current_user.language
        when "English"          then "en"
        when "Spanish"          then "es"
        when "Bahasa Indonesia" then "in"
        else "en"
      end
    else
      I18n.locale = "en"
    end
    
    I18n.backend.send(:init_translations)
  end     

  # ----------------------------------------------------------------------------------------------------------
  # Convert foreign language bible books to English
  # TODO: should also handle the abbreviated form of a book name
  # ----------------------------------------------------------------------------------------------------------   
  def translate_to_english(book)
   
    if I18n.backend.send(:translations)
      # TODO: should change 'index' in line below to 'key'
      return I18n.backend.send(:translations)[I18n.locale.to_sym][:book][:name].index(book).to_s
    else
      return book
    end
  end


  # ----------------------------------------------------------------------------------------------------------
  # Returns list of identical verses
  # ----------------------------------------------------------------------------------------------------------
  def identical_verses( ref )
    iv = Hash[
      ["Luke", 12, 34]      => ["Matthew", 6, 21],
      ["Matthew", 6, 21]    => ["Luke", 12, 34],
      ["Proverbs", 14, 12]  => ["Proverbs", 16, 25],
      ["Proverbs", 16, 25]  => ["Proverbs", 14, 12],
      ["Judges", 21, 25]    => ["Judges", 17, 6],
      ["Judges", 17, 6]     => ["Judges", 21, 25],
      ["Matthew", 25, 21]   => ["Matthew", 25, 23],
      ["Matthew", 25, 23]   => ["Matthew", 25, 21],
      ["Leviticus", 19, 30] => ["Leviticus", 26, 2],
      ["Leviticus", 26, 2]  => ["Leviticus", 19, 30],
      ["Psalms", 107,  8]   => [["Psalms", 107, 15], ["Psalms", 107, 22], ["Psalms", 107, 31]],
      ["Psalms", 107, 15]   => [["Psalms", 107,  8], ["Psalms", 107, 22], ["Psalms", 107, 31]],
      ["Psalms", 107, 22]   => [["Psalms", 107,  8], ["Psalms", 107, 15], ["Psalms", 107, 31]],
      ["Psalms", 107, 31]   => [["Psalms", 107,  8], ["Psalms", 107, 15], ["Psalms", 107, 22]]      
    ]
    
    return iv[ ref ] || []
  end


  # ----------------------------------------------------------------------------------------------------------
  # Return memorization status TODO: this should be redundant now
  # ----------------------------------------------------------------------------------------------------------
  def verse_status(n, efactor, interval)  
    if (interval>30)
      return "Memorized"
    else
      return "Learning"
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Parse verse reference -- this function is used a lot
  # Input:    string, eg. "1 John 2:5" or "1 Jn 2:5"   
  # Outputs:  array,  eg. "[errorcode, '1 John', 2, 5]
  # ----------------------------------------------------------------------------------------------------------   
  def parse_verse(parse_string)
    
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
  
      if !BIBLEBOOKS.include?(full_book_name(book)) # This is not a book of the bible
      	logger.info("*** Could not find book: #{book}")
        return 2, book # Error code for invalid book of the bible
      else
        chapter, verse  = vsref.split(/:|vs/)
        if chapter and verse
          return false, full_book_name(book), chapter.slice(/[0-9]+/).to_i, verse.slice(/[0-9]+/).to_i
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
 
  # ----------------------------------------------------------------------------------------------------------
  # Checks validity of bible book name
  # Input:  'Deuteronomy' or 'Deut' = true
  # Output: true or false
  # ----------------------------------------------------------------------------------------------------------  
  def valid_bible_book(str)
    return (BIBLEBOOKS.include?(str.titleize) || BIBLEABBREV.include?(str.titleize) || BIBLEBOOKS.include?(str))
  end

  # ----------------------------------------------------------------------------------------------------------
  # Save verse to database
  # Input:  translation, book, chapter, versenum, text
  # Output: Verse (object)
  # ---------------------------------------------------------------------------------------------------------- 

  def save_verse_to_db(tl, book, chapter, verse, txt)
    vs = Verse.new
    vs.translation = tl.to_s
    vs.book        = full_book_name(book).to_s   # We want to convert abbreviations to full book names
    vs.book_index  = book_index(book)
    vs.chapter     = chapter.to_i
    vs.versenum    = verse.to_i
    if (tl=='ESV')
      vs.text      = Esv.request(book + ' ' + chapter.to_s + ':' + verse.to_s)
      vs.text      = vs.text.gsub(/-{2,}/, " - ")  # replace double-dash with single dash
      vs.text      = vs.text.gsub(/\s{2,}/, " ").strip # remove extra white space      
      vs.verified  = true
      if vs.text.include?("ERROR")
        logger.info("*** ESV Query returned an error: #{vs.text}")
        vs.text      = txt.strip # Overwrite with whatever user entered instead
        vs.verified  = false
      end
    else
      vs.text      = txt.strip
    end

    vs.save
    return vs
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Returns bible book index
  # Input:  'Deuteronomy' or 'Deut'
  # Output: 5 or nil if book doesn't exist
  # Note: This breaks if string is not a valid book because you can't add 1 + nil
  # Note: The last check is required to handle 'Song of Songs' because titleizing it becomes "Song Of Songs"
  # ----------------------------------------------------------------------------------------------------------  
  def book_index(str)
    if x = (BIBLEBOOKS.index(str.titleize) || BIBLEABBREV.index(str.titleize) || BIBLEBOOKS.index(str))
      return 1+x
    else
      return nil
    end
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Checks for excessively long verses - indication of multiple verse entry
  # Input:  "In the beginning, God created the heavens and the earth"
  # Output: True (if verse too long)
  # ----------------------------------------------------------------------------------------------------------   
  def verse_too_long?(txt)
    return txt.split.length > 91
  end

  # ----------------------------------------------------------------------------------------------------------
  # Checks whether verse is in DB
  # Input:  Deuteronomy, 3, 6, NIV
  # Output: False (if verse not in DB) otherwise returns ID
  # ---------------------------------------------------------------------------------------------------------- 
  def verse_in_db(book, chapter, versenum, translation)
    
    ref =  Verse.find( :first, 
                       :conditions => ["book = ? and chapter = ? and versenum = ? and translation = ?", 
                                        full_book_name(book), chapter, versenum, translation])

    return ref
  end
 
  # ----------------------------------------------------------------------------------------------------------
  # Checks whether verse is in current user's memory list
  # Input:  verse ID
  # Output: FALSE (if verse not in users memory list) otherwise returns Memverse object
  # ----------------------------------------------------------------------------------------------------------   
  def verse_in_userlist(vs)
    
    vs.alternative_translations.each { |tl|
    
      tl.memverses.each { |mv| 
        if mv.user == current_user
          return mv
        end
      }
    }
    return false
    
    # old code
    # Memverse.find(:first, :conditions => ["user_id = ? and verse_id = ?", current_user.id, vs])    
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Converts DB format to verse
  # Input:  Deuteronomy, 3, 6
  # Output: Deuteronomy 3:6
  # ----------------------------------------------------------------------------------------------------------  
  def db_to_vs(book, chapter, verse)
    return abbr(book) + ' ' + chapter.to_s + ':' + verse.to_s
  end 
 
  # ----------------------------------------------------------------------------------------------------------
  # Abbreviates book names
  # Input:  'Deuteronomy'
  # Output: 'Deut'
  # ----------------------------------------------------------------------------------------------------------  
  def abbr(book)
    return BIBLEABBREV[book_index(book)-1]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Lengthens book names
  # Input:  'Deut' or 'Deuteronomy'
  # Output: 'Deuteronomy'
  # ----------------------------------------------------------------------------------------------------------   
  def full_book_name(book)
    if valid_bible_book(book)
      return BIBLEBOOKS[book_index(book)-1] || BIBLEABBREV[book_index(book)-1]
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Retrieve memory verse
  #   Input: verse_id
  #   Output: "John 3:16"
  # ----------------------------------------------------------------------------------------------------------  
  def get_memverse(verse_id)
    vs    = Verse.find(verse_id)
    if vs
      verse = db_to_vs(vs.book, vs.chapter, vs.versenum)
      return verse
    else
      # In case the memory verse is being retrieved from a session variable but has been deleted
      return false
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Retrieve previous/next memory verse NOTE: Rather use version in Memverse model - Don't use these!
  #   Input: verse_id
  #   Output: mv_id
  # ----------------------------------------------------------------------------------------------------------   
  def prev_verse(verse_id)  

    errorcode, book, chapter, verse = parse_verse( get_memverse(verse_id) )   

    # Check for 3 conditions
    #   verse parses correctly
    #   previous verse is in db
    #   and prev_verse is in user's list of memory verses  
    if (!errorcode) and prev_vs = verse_in_db(book, chapter, verse-1, verse_id.translation) and prev_mv = verse_in_userlist(prev_vs) 
      logger.debug("*** Found previous verse: #{prev_mv.verse.ref}")
      return prev_mv.id 
    else
      logger.debug("*** No previous verse found")
	  logger.debug("***** Verse parsed with error code: #{errorcode}")
      return nil
    end
    
  end
  
  
  def next_verse(verse_id)

    errorcode, book, chapter, verse = parse_verse( get_memverse(verse_id) )   

    # Check for 3 conditions
    #   verse parses correctly
    #   previous verse is in db
    #   and prev_verse is in user's list of memory verses  
    if (!errorcode) and next_vs = verse_in_db(book, chapter, verse+1, verse_id.translation) and next_mv = verse_in_userlist(next_vs) 
      return next_mv.id 
    else
      return nil
    end
    
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Find first verse in memory verse sequence for a given user NOTE: Rather use version in Memverse model
  #   Input: mv_id
  #   Output: mv_id
  # ----------------------------------------------------------------------------------------------------------   
  def first_verse(mv)

    while mv.prev_verse
      start_vs_id = mv.prev_verse
      mv = Memverse.find(mv.prev_verse)
    end
    
    return start_vs_id
   
  end

 
  # ----------------------------------------------------------------------------------------------------------
  # For URL escaping/unescaping
  #   Input: URL with encoded characters
  #   Output: string
  # ----------------------------------------------------------------------------------------------------------     
  def url_escape(string)
    string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
    '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '+')
  end
  
  def url_unescape(string)
    string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
    [$1.delete('%')].pack('H*')
    end
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Update starting verse for downstream verses
  #   Input: mv (obj) <-- this is the first verse in the sequence which has a pointer to the first verse
  # ----------------------------------------------------------------------------------------------------------     
  def update_downstream_start_verses(mv)
    
    # If mv is pointing to a start verse, use that as the first verse, otherwise set mv as the first verse
    new_starting_verse = mv.first_verse || mv.id # || returns first operator that satisfies condition
   
    while mv.next_verse
      mv = Memverse.find(mv.next_verse)
      mv.first_verse = new_starting_verse
      mv.save
    end
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Does a verse belong to the current user
  #   Input: verse_id
  #   Output: 'true' if verse is a memory verse (IN ANY TRANSLATION) for current user
  # ----------------------------------------------------------------------------------------------------------   
  def vs_belongs_to_current_user(verse_id)
    vs  = Verse.find(verse_id)
        
    users_of_verse = vs.memverses
    users_of_verse.each { |user|
      if user.user_id == current_user.id
        return true
      end
    }
    
    # Look for other translations
    # mem_vs = Memverse.find(:all, :conditions => ["user_id = ?", current_user.id])       
    
    return false
  end
   
  # ----------------------------------------------------------------------------------------------------------
  # Returns true (0) if str is a valid bible reference otherwise nil
  # ----------------------------------------------------------------------------------------------------------  
  def valid_ref(str)
    return str =~ /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:|(\s?vs\s?))[0-9]+/i
  end   

  private  
  
  # ----------------------------------------------------------------------------------------------------------
  # Check for mobile devices
  # ----------------------------------------------------------------------------------------------------------      
  def mobile_device?  
  	
  	return false # TODO: not supporting mobile devices for now ... uncomment below and remove this line to add support
    # if session[:mobile_param]  
    #   session[:mobile_param] == "1"  
    # else  
    #   request.user_agent =~ /Mobile|webOS/  
    # end  
  end  
  helper_method :mobile_device?  
      
  def prepare_for_mobile  
    session[:mobile_param] = params[:mobile] if params[:mobile]  
    request.format = :mobile if mobile_device?  
  end    
    
  protected
  
  # Automatically respond with 404 for ActiveRecord::RecordNotFound
  def record_not_found
    render :file => File.join(Rails.root, 'public', '404.html'), :status => 404
  end
end

