module ApplicationHelper
  
  
  BIBLEBOOKS = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
                '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
                'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 
                'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
                'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
                'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
                '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']  
  
  

  BIBLEABBREV = ['Gen', 'Ex', 'Lev', 'Num', 'Deut', 'Josh', 'Judg', 'Ruth', '1 Sam', '2 Sam',
                '1 Kings', '2 Kings','1 Chron', '2 Chron', 'Ezra', 'Neh', 'Es', 'Job', 'Ps', 'Prov',
                'Eccl', 'Song', 'Isa', 'Jer', 'Lam', 'Ezk', 'Dan', 'Hos', 'Joel', 
                'Amos', 'Obad', 'Jonah', 'Mic', 'Nahum', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal', 'Matt',
                'Mark', 'Luke', 'Jn', 'Acts', 'Rom', '1 Cor', '2 Cor', 'Gal', 'Eph', 'Phil',
                'Col', '1 Thess', '2 Thess', '1 Tim', '2 Tim', 'Tit', 'Phil', 'Heb', 'James',
                '1 Pet', '2 Pet', '1 John', '2 John', '3 John', 'Jude', 'Rev']                  
    
  # Sets the page title and outputs title if container is passed in.
  # eg. <%= title('Hello World', :h2) %> will return the following:
  # <h2>Hello World</h2> as well as setting the page title.
  def title(str, container = nil)
    @page_title = str
    content_tag(container, str) if container
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Outputs the corresponding flash message if any are set
  # ----------------------------------------------------------------------------------------------------------  
  def flash_messages
    messages = []
    %w(notice warning error).each do |msg|
#      messages << content_tag(:div, html_escape(flash[msg.to_sym]), :id => "flash-#{msg}") unless flash[msg.to_sym].blank?
      messages << content_tag(:div, flash[msg.to_sym], :id => "flash-#{msg}") unless flash[msg.to_sym].blank?
    end
    messages
  end
    
  # ----------------------------------------------------------------------------------------------------------
  # Returns bible book index
  # Input:  'Deuteronomy' or 'Deut'
  # Output: 5 or nil if book doesn't exist
  # Note: This breaks if string is not a valid book because you can't add 1 + nil
  # ----------------------------------------------------------------------------------------------------------  
  def book_index(str)
    if x = (BIBLEBOOKS.index(str.titleize) || BIBLEABBREV.index(str.titleize))
      return 1+x
    else
      return nil
    end
  end  


  # ----------------------------------------------------------------------------------------------------------
  # Adds 'selected' class to menu item matching current page
  # ---------------------------------------------------------------------------------------------------------- 
  def tab( tab, include_class_text = true )

    value = ''
    value = 'selected'   if tab
    
    if include_class_text
      'class="' << value << '"'
    else
      value
    end
  end  

  
  # ----------------------------------------------------------------------------------------------------------
  # This function replaces 'escape_javascript' which used to work under Rails 2.2.2 but stopped working in 
  # Rails 2.3.4. For some reason, verses were being truncated on semicolons.
  # ----------------------------------------------------------------------------------------------------------   
  VS_ESCAPE_MAP = {
  '\\'    => '\\\\',
  '</'    => '<\/',
  "\r\n"  => '\n',
  "\n"    => '\n',
  "\r"    => '\n',
  ";"     => "%3B",
  '"'     => '\\"',
  "'"     => "\\'" }
  
  def escape_verse(javascript)
    if javascript
      javascript.gsub(/(\\|<\/|\r\n|[\n\r;"'])/) { VS_ESCAPE_MAP[$1] }
    else
      ''
    end
  end

  
  
end
