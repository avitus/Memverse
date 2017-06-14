# coding: utf-8

class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale, :prepare_for_mobile

  def bloggity_user
    current_user
  end
  helper_method :bloggity_user

  helper :all # include all helpers, all the time
  protect_from_forgery
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  # Admin Authorization
  helper_method :admin?
  protected
  def admin?
    # current_user && current_user.has_role?('admin')  # ALV - use this method when CanCan properly implemented
    current_user && current_user.admin?
  end

  def authorize
    unless admin?
      flash[:error] = "Unauthorized access."
      redirect_to root_path
      false
    end
  end

  # Localization
  def set_locale
    # if params[:locale] is nil then I18n.default_locale will be used
    if current_user
      I18n.locale = case current_user.language
        when "English"           then "en"
        when "Spanish"           then "es"
        when "Bahasa Indonesia"  then "in"
        when "Chinese"           then "zh"
        when "Korean"            then "ko"
        when "Turkish"           then "tr"

        else "en"
      end
    else
      I18n.locale = "en"
    end
  end

  # Convert foreign language Bible books to English
  def translate_to_english(book)
    Book.find_by_name(book).to_lang(:en).try(:name)
  end


  # Returns list of identical verses
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
  # Parse verse reference -- this function is used a lot
  # Input:    string, eg. "1 John 2:5" or "1 Jn 2:5"
  # Outputs:  array,  eg. "[errorcode, '1 John', 2, 5]
  # TODO: Should this be in application_helper.rb ?
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

      if !full_book_name(book) # not a valid book of the Bible
      	logger.info("*** Could not find book: #{book} when parsing string #{parse_string}")
        return 2, book # Error code for invalid book of the Bible
      else
        chapter, verse = vsref.split(/:|;|vs/)
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
      vs.text      = vs.text.gsub(/-{2,}/, " — ")  # replace double-dash with single dash
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
  # Converts DB format to verse
  # Input:  Deuteronomy, 3, 6
  # Output: Deuteronomy 3:6
  # ----------------------------------------------------------------------------------------------------------
  def db_to_vs(book, chapter, verse)
    "#{Book.find_by_name(book).abbrev} #{chapter}:#{verse}"
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

  # Returns true (0) if str is a valid bible reference otherwise nil
  # @todo This should not be duplicated here and in parser.rb
  # @todo Support Chinese and other languages
  def valid_ref(str)
    return str =~ /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:|(\s?vs\s?))[0-9]+/i
  end

  private

  # Check for mobile devices
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

  # https://github.com/plataformatec/devise#strong-parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :referred_by])
  end

  # Automatically respond with 404 for ActiveRecord::RecordNotFound
  def record_not_found
    render :file => File.join(Rails.root, 'public', '404.html'), :status => 404
  end
end
