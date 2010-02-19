class Verse < ActiveRecord::Base

  require 'cgi'  
  require 'open-uri'
  require 'nokogiri'

  
  # Relationships
  has_many :memverses
  
  # Validations
  validates_presence_of :translation, :book, :chapter, :versenum, :text

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
                'Col', '1 Thess', '2 Thess', '1 Tim', '2 Tim', 'Tit', 'Phlm', 'Heb', 'James',
                '1 Pet', '2 Pet', '1 John', '2 John', '3 John', 'Jude', 'Rev']

  # ----------------------------------------------------------------------------------------------------------
  # Outputs friendly verse reference: eg. "John 3:16"
  # ----------------------------------------------------------------------------------------------------------   
  def ref
    return abbr(book) + ' ' + chapter.to_s + ':' + versenum.to_s
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return data about testament
  # ----------------------------------------------------------------------------------------------------------  
  def old_testament?
    return book_index < 40
  end

  def new_testament?
    return book_index >= 40
  end

  def testament
    book_index >= 40 ? "New" : "Old"
  end
  
  def history?
    (1..17).include?(book_index)
  end
 
  def wisdom?
    (18..22).include?(book_index)
  end  
  
  def prophecy?
    (23..39).include?(book_index)
  end

  def gospel?
    (40..43).include?(book_index)
  end

  def epistle?
    (45..65).include?(book_index)
  end
  

  # ----------------------------------------------------------------------------------------------------------
  # Returns hash of verses and number of users for each verse
  # ----------------------------------------------------------------------------------------------------------   
  def self.rank_verse_popularity(limit = 25)
    
    vs_popularity = Hash.new(0) 
    
    find(:all).each { |vs|
      vs_popularity[vs.ref] += vs.memverses.count # returns an array of associated memory verses
    }   
    return vs_popularity.sort{|a,b| a[1]<=>b[1]}.reverse[0..limit]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Check whether verse exists in DB - Note: checking for verse in database requires full length book name
  # ----------------------------------------------------------------------------------------------------------   
  def self.exists_in_db(bk, ch, vs, tl)
    find(:first, :conditions => { :book => bk, :chapter => ch, :versenum => vs, :translation => tl })
  end

  # ----------------------------------------------------------------------------------------------------------
  # Checks whether verse has been verified or not
  # Input:  A verse ID
  # Output: True/False depending on whether verse is/isn't verified
  # ----------------------------------------------------------------------------------------------------------  
  def verified?
    return self.verified
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check with biblegateway for correctly entered verse
  # ----------------------------------------------------------------------------------------------------------  
  def web_check
    
    tl = case self.translation
      when "NAS" then "NASB"
      when "NKJ" then "NKJV"
      else self.translation.downcase
    end
    
    
    url = 'http://www.biblegateway.com/passage/?search=' + CGI.escape(self.ref) + '&version=' + tl.to_s
    doc = Nokogiri::HTML(open(url))
    # The third gsub removes weirdly encoded characters at the start of strings
    txt = doc.at_css(".result-text-style-normal").to_s.gsub(/<sup.+?<\/sup>/, "").gsub(/<h(4|5).+?<\/h(4|5)>/,"").gsub(/<\/?[^>]*>/, "").gsub(/[\x80-\xff]/,"").split("Footnotes")[0]
    txt = txt.strip unless !txt
    txt == self.text ? true : txt
  end

  # ----------------------------------------------------------------------------------------------------------
  # Create mnemonic for verse text
  # ---------------------------------------------------------------------------------------------------------- 
  def mnemonic
    self.text.gsub(/[^a-zA-Z,. ]/, '').split.map { |x| 
      if (x.last =~ /[a-zA-Z]/).nil?
        x[0].chr + x.last
      else
        x[0].chr
      end
      }.join(" ")
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns array of all translations for a given verse
  # Input:  A verse ID
  # Output: Array of all translations of a given verse
  # ----------------------------------------------------------------------------------------------------------   
  def alternative_translations
    Verse.find( :all, :conditions => { :book => self.book, :chapter => self.chapter, :versenum => self.versenum } )
  end

  # ----------------------------------------------------------------------------------------------------------
  # Checks whether verse is locked
  # Input:  A verse ID
  # Output: True/False depending on whether verse is/isn't locked
  # ----------------------------------------------------------------------------------------------------------  
  def locked?
    return self.memverses.length > 1
  end   

  # ----------------------------------------------------------------------------------------------------------
  # Returns bible book index
  # Input:  'Deuteronomy' or 'Deut'
  # Output: 5 or nil if book doesn't exist
  # Note: This breaks if string is not a valid book because you can't add 1 + nil
  # Note: The last check is required to handle 'Song of Songs' because titleizing it becomes "Song Of Songs"
  # ----------------------------------------------------------------------------------------------------------  
  def book_index(str=self.book)
    if x = (BIBLEBOOKS.index(str.titleize) || BIBLEABBREV.index(str.titleize) || BIBLEBOOKS.index(str))
      return 1+x
    else
      return nil
    end
  end  

  # ============= Protected below this line ==================================================================
  protected
  
  # ----------------------------------------------------------------------------------------------------------
  # Abbreviates book names
  # Input:  'Deuteronomy'
  # Output: 'Deut'
  # ----------------------------------------------------------------------------------------------------------  
  def abbr(book)
    return BIBLEABBREV[book_index(book)-1]
  end  
  
  
  
end