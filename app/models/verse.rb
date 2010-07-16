#    t.string   "translation",                    :null => false
#    t.integer  "book_index",                     :null => false
#    t.string   "book",                           :null => false
#    t.string   "chapter",                        :null => false
#    t.string   "versenum",                       :null => false
#    t.text     "text"
#    t.datetime "created_at"
#    t.datetime "updated_at"
#    t.boolean  "verified",    :default => false, :null => false
#    t.boolean  "error_flag",  :default => false, :null => false

class Verse < ActiveRecord::Base

  acts_as_taggable # Alias for 'acts_as_taggable_on :tags'

  require 'cgi'  
  require 'open-uri'
  require 'nokogiri'

  
  # Relationships
  has_many :memverses
  has_and_belongs_to_many :collections
  
  # Validations
  validates_presence_of :translation, :book, :chapter, :versenum, :text

  named_scope :old_testament, :conditions => { :book_index =>  1..39 }
  named_scope :new_testament, :conditions => { :book_index => 40..66 }
  
  named_scope :history,   :conditions => { :book_index =>  1..17 }
  named_scope :wisdom,    :conditions => { :book_index => 18..22 }
  named_scope :prophecy,  :conditions => { :book_index => 23..39 }
  named_scope :gospel,    :conditions => { :book_index => 40..43 }
  named_scope :epistle,   :conditions => { :book_index => 45..65 }

  named_scope :tl, lambda { |tl| {:conditions => ['translation = ?', tl ]} }
                            
  # ----------------------------------------------------------------------------------------------------------
  # Outputs friendly verse reference: eg. "Jn 3:16"
  # ----------------------------------------------------------------------------------------------------------   
  def ref
    book_tl = I18n.t abbr(book).to_sym, :scope => [:book, :abbrev]     
    return book_tl + ' ' + chapter.to_s + ':' + versenum.to_s
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
  def self.rank_verse_popularity(limit=25, book=nil)
    
    vs_popularity = Hash.new(0) 
    
    if book
      find(:all, :conditions => { :book => book}).each { |vs| vs_popularity[vs.ref] += vs.memverses.count }
    else
      find(:all).each { |vs| vs_popularity[vs.ref] += vs.memverses.count } # returns an array of associated memory verses
    end
    return vs_popularity.sort{|a,b| a[1]<=>b[1]}.reverse[0..limit]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Check whether verse exists in DB - Note: checking for verse in database requires full length book name
  # ----------------------------------------------------------------------------------------------------------   
  def self.exists_in_db(bk, ch, vs, tl)
    find(:first, :conditions => { :book => bk, :chapter => ch, :versenum => vs, :translation => tl })
  end


  # ----------------------------------------------------------------------------------------------------------
  # Return subsequent verse in same translation (if it exists) 
  # ----------------------------------------------------------------------------------------------------------   
  def following_verse
    if self.last_in_chapter?
      Verse.find(:first, :conditions => { :book         => self.book, 
                                          :chapter      => self.chapter.to_i+1, 
                                          :versenum     => 1,               
                                          :translation  => self.translation })
    else
      Verse.find(:first, :conditions => { :book         => self.book, 
                                          :chapter      => self.chapter,   
                                          :versenum     => self.versenum.to_i+1, 
                                          :translation  => self.translation })
    end
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
  # Is this the last verse of a chapter?
  # ---------------------------------------------------------------------------------------------------------- 
  def last_in_chapter?
    !FinalVerse.find(:first, :conditions => { :book => self.book, :chapter => self.chapter, :last_verse => self.versenum }).nil?
  end

  # ----------------------------------------------------------------------------------------------------------
  # Find the last verse of the chapter
  # ---------------------------------------------------------------------------------------------------------- 
  def end_of_chapter_verse
    FinalVerse.find(:first, :conditions => { :book => self.book, :chapter => self.chapter })
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns array containing all verses in chapter but 'false' if any verse is missing
  # ----------------------------------------------------------------------------------------------------------   
  
  def entire_chapter
    
    full_chapter  = Array.new
    bk            = self.book
    ch            = self.chapter
    tl            = self.translation
    
    num_verses = self.end_of_chapter_verse.last_verse
    
    (1..num_verses).each { |vs|
      full_chapter << Verse.exists_in_db(bk, ch, vs, tl)
    }
    
    return full_chapter
    
  end


  # ----------------------------------------------------------------------------------------------------------
  # Returns all tags associated with a given verse
  # ---------------------------------------------------------------------------------------------------------- 
  def all_user_tags(numtags = 3)
    
    all_tags = Hash.new(0)
    
    self.alternative_translations.each { |tl|
      tl.memverses.each { |mv|
        mv.tags.each { |tag|
          all_tags[tag] += 1
        }
      }
    }
    
    return all_tags.sort{|a,b| a[1]<=>b[1]}.reverse[0...numtags]
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

    txt = doc.at_css(".result-text-style-normal").to_s.gsub(/<sup.+?<\/sup>/, "").gsub(/<h(4|5).+?<\/h(4|5)>/,"").gsub(/<\/?[^>]*>/, "")
    
    # Replace angled double and single quotes with ASCII equivalents
    txt = txt.gsub(/[’‘]/, "\'")
    txt = txt.gsub(/[“”]/, '"')
    # Removes weirdly encoded characters at the start of strings
    txt = txt.gsub(/[\x80-\xff]/,"")
    txt = txt.split("Footnotes")[0] unless !txt
    txt = txt.split("Cross")[0] unless !txt
    txt = txt.gsub(/\s{2,}/, " ").strip unless !txt               # remove extra white space in verse and at beginning and end
    txt == self.text ? true : txt
  end

  # ----------------------------------------------------------------------------------------------------------
  # Create mnemonic for verse text
  # TODO: Add support for " ', long dashes (—) and other punctuation  
  # ---------------------------------------------------------------------------------------------------------- 
  def mnemonic
    self.text.gsub(/[^a-zA-Záéíóúüñ¿¡?!,:;.\- ]/, '').split.map { |x| 
      if (x.last =~ /[a-zA-Záéíóúüñ]/).nil? # The word is terminated with a non letter
        x.match(/^(.)/).to_s + x.last
#      elsif (x.match(/^(.)/) =~ /[a-zA-Záéíóúüñ]/).nil? # The word starts with a non letter (Spanish texts)
#        x.match(/^(..)/).to_s
      else
        x.match(/^(.)/) # This handles accented letters properly (^ matches start of word, (.) matches first char)
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
  # Returns array of all translations for a given verse
  # Input:  A verse ID
  # Output: verse in different translation or nil
  # ----------------------------------------------------------------------------------------------------------  
  def switch_tl(tl)
    Verse.find( :first, :conditions => { :translation => tl, :book => self.book, :chapter => self.chapter, :versenum => self.versenum } )
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns array of all memory verses for a given reference, irrespective of translation
  # Input:  A verse ID
  # Output: Array of mv
  # ---------------------------------------------------------------------------------------------------------- 
  def all_memory_verses
    all_mv = Array.new
    
    self.alternative_translations.each { |vs| 
      all_mv << vs.memverses 
    }
    
    return all_mv.flatten   
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