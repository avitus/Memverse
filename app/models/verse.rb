# coding: utf-8

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

  extend HTMLDiff

  acts_as_taggable # Alias for 'acts_as_taggable_on :tags'

#  Rails 2
#  require 'cgi'  
#  require 'open-uri'
#  require 'nokogiri'

  before_destroy :delete_memverses
  
  
  # Relationships
  has_many :memverses
  
  # Validations
  validates_presence_of :translation, :book, :chapter, :versenum, :text

  scope :old_testament, where(:book_index =>  1..39)
  scope :new_testament, where(:book_index => 40..66)
  
  scope :history,  where(:book_index =>  1..17)
  scope :wisdom,   where(:book_index => 18..22)
  scope :prophecy, where("book_index BETWEEN 23 AND 39 OR book_index = 66")
  scope :gospel,   where(:book_index => 40..43)
  scope :epistle,  where(:book_index => 45..65)

  scope :tl, lambda { |tl| where('translation = ?', tl) }
                            

  # ----------------------------------------------------------------------------------------------------------
  # Sphinx Index
  # ----------------------------------------------------------------------------------------------------------   
  define_index do
		# fields
		indexes translation, :sortable => true
		indexes text
		indexes [book, chapter, versenum], :as => :reference	
		    
		# attributes
		has created_at
  end

                            
  # ----------------------------------------------------------------------------------------------------------
  # Sort Verse objects according to biblical book order
  # ----------------------------------------------------------------------------------------------------------    
  def <=>(o)
   
   # Compare book
   book_cmp = self.book_index.to_i <=> o.book_index.to_i
   return book_cmp unless book_cmp == 0

   # Compare chapter
   chapter_cmp = self.chapter.to_i <=> o.chapter.to_i
   return chapter_cmp unless chapter_cmp == 0

   # Compare verse
   verse_cmp = self.versenum.to_i <=> o.versenum.to_i
   return verse_cmp unless verse_cmp == 0

   # Otherwise, compare IDs
   return self.id <=> o.id
  end                            
                            
  # ----------------------------------------------------------------------------------------------------------
  # Outputs friendly verse reference: eg. "Jn 3:16"
  # ----------------------------------------------------------------------------------------------------------   
  def ref
    book_tl = I18n.t abbr(book).to_sym, :scope => [:book, :abbrev]     
    return book_tl + ' ' + chapter.to_s + ':' + versenum.to_s
  end

  # ----------------------------------------------------------------------------------------------------------
  # Outputs friendly verse reference: eg. "John 3:16"
  # ----------------------------------------------------------------------------------------------------------   
  def ref_long
    book_tl = I18n.t book.to_sym, :scope => [:book, :name]     
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
      find(:all, :conditions => { :book => book}).each { |vs| vs_popularity[vs.ref] += vs.memverses_count }
    else
    	# Don't cache records in memory
	    ActiveRecord::Base.uncached do
	      Verse.find_each do |vs|
	        vs_popularity[vs.ref] += vs.memverses_count
	      end
	    end    	
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
  	if self.book == "3 John"
	  if ["NAS", "NLT", "ESV"].include?(self.translation)
		return self.versenum.to_i == 15
	  else
		return self.versenum.to_i == 14
	  end
  	else
      !FinalVerse.find(:first, :conditions => { :book => self.book, :chapter => self.chapter, :last_verse => self.versenum }).nil?
    end
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Find the last verse of the chapter
  # ---------------------------------------------------------------------------------------------------------- 
  def end_of_chapter_verse
  	if self.book == "3 John"
  		if ["NAS", "NLT", "ESV"].include?(self.translation)
  			FinalVerse.new(:book => "3 John", :chapter => 1, :last_verse => 15)
  		else
  			FinalVerse.new(:book => "3 John", :chapter => 1, :last_verse => 14)
  		end
  	else
    	FinalVerse.find(:first, :conditions => { :book => self.book, :chapter => self.chapter })
    end
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns array containing all verses in chapter but 'false' if any verse is missing
  # ----------------------------------------------------------------------------------------------------------   
  
  def entire_chapter
    
    full_chapter  = Array.new
    bk            = self.book
    ch            = self.chapter
    tl            = self.translation
    
    if self.end_of_chapter_verse
      num_verses = self.end_of_chapter_verse.last_verse 
    
      (1..num_verses).each { |vs|
        full_chapter << Verse.exists_in_db(bk, ch, vs, tl)
      }
    end
    
    return full_chapter
    
  end


  # ----------------------------------------------------------------------------------------------------------
  # Returns all tags associated with a given verse
  # ---------------------------------------------------------------------------------------------------------- 
  def all_user_tags(numtags = 5)
    
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
  # Return list of duplicate verses (if any)
  # ----------------------------------------------------------------------------------------------------------
  def has_duplicates?
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
    
    return iv[ [self.book, self.chapter.to_i, self.versenum.to_i] ] || []    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check with biblegateway for correctly entered verse
  # ----------------------------------------------------------------------------------------------------------  
  def web_check
  
    on_bg = BibleGateway.new(self.translation.to_sym).lookup(self.ref)[:content]  
    in_db = self.text
    
    # Ok to differ in style of quotation marks  
    in_db = in_db.gsub(/[’‘]/, "\'")
    in_db = in_db.gsub(/[“”]/, '"')
    
    if on_bg
		  on_bg = on_bg.gsub(/[’‘]/, "\'") 
		  on_bg = on_bg.gsub(/[“”]/, '"')
		end
	      
    (on_bg == in_db) ? true : on_bg  # return what we pulled from web if different
  end

	def bg_link
		BibleGateway.new(self.translation.to_sym).passage_url(self.ref)
	end

  # ----------------------------------------------------------------------------------------------------------
  # Create mnemonic for verse text
  # ---------------------------------------------------------------------------------------------------------- 
  def mnemonic
    self.text.gsub(/([\wáéíóúüñ])([\wáéíóúüñ]|[\-'’][\wáéíóúüñ])*/,'\1')
    # In simpler language we are matching:
    # (Any alphanumerical character) followed by (all consecutive alphanumerical characters OR a -'’ character followed by an alphanumerical character)
    # The star (*) means we repeat the previous item as many times as possible (refers to set of parentheses matching alphanumerical OR -'’ followed by alphanumerical
    # The '\1' at the end is the value for what we replace these matches with, and it refers to whatever matches the first parentheses (in our case, the first character). Using a '\2' would match the second parentheses, etc.
    # Adapted from JavaScript found at http://productivity501.com/wp-content/uploads/tools/memorize-first-letter-tool.html
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
  # Returns same verse in a different translation
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
  
  # ============= Private below this line - can only be called on self =======================================
  private
  
  def delete_memverses
    Rails.logger.warn("*** Deleting the following verse: #{self.ref} [#{self.translation}]  ")
    Rails.logger.warn("*** Deleting associated memory verses")
    Rails.logger.warn("*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    self.memverses.each { |mv|
      Rails.logger.warn("*** #{mv.user.name_or_login}")
    }
    
    self.memverses.destroy_all
  end
  
end
