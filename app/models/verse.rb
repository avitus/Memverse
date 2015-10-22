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

  include RocketPants::Cacheable   # Allow for access via API

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :Verse do
    key :required, [:translation, :book_index, :book, :chapter, :versenum]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :translation do
      key :type, :string
    end 
    property :book_index do
      key :type, :integer
      key :format, :int64
    end 
    property :book do
      key :type, :string
    end 
    property :chapter do
      key :type, :string
    end 
    property :versenum do
      key :type, :integer
      key :format, :int64
    end
    property :text do
      key :type, :string
    end     
    property :created_at do
      key :type, :string
      key :format, :dateTime
    end 
    property :updated_at do
      key :type, :string
      key :format, :dateTime
    end 
    property :verified do
      key :type, :boolean
    end  
    property :verified do
      key :type, :boolean
    end  
    property :error_flag do
      key :type, :boolean
    end   
    property :uberverse_id do
      key :type, :integer
      key :format, :int64
    end  
    property :checked_by do
      key :type, :string
    end  
    property :memverses_count do
      key :type, :integer
      key :format, :int64
    end  
    property :difficulty do
      key :type, :number
    end 
    property :popularity do
      key :type, :number
    end            
  end
  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------

  acts_as_taggable # Alias for 'acts_as_taggable_on :tags'

  before_destroy :delete_memverses
  before_create  :validate_ref
  before_save    :cleanup_text, :associate_with_uberverse

  after_save :schedule_web_check

  # Relationships
  has_many :memverses
  belongs_to :uberverse

  # Validations
  validates_presence_of   :translation, :book, :chapter, :versenum, :text

  scope :old_testament, -> { where(:book_index =>  1..39) }
  scope :new_testament, -> { where(:book_index => 40..66) }

  scope :history,  -> { where("book_index BETWEEN 1  AND 17 OR book_index = 44") }
  scope :wisdom,   -> { where(:book_index => 18..22) }
  scope :prophecy, -> { where("book_index BETWEEN 23 AND 39 OR book_index = 66") }
  scope :gospel,   -> { where(:book_index => 40..43) }
  scope :epistle,  -> { where(:book_index => 45..65) }

  scope :tl, ->(tl) { where('translation = ?', tl) }

  scope :canonical_sort, -> { order("book_index, chapter, versenum") }

  # Sort Verse objects according to biblical book order
  # 
  # canonical_sort scope preferred
  #
  # @param o [Verse] The verse to sort in relation with.
  def <=>(o)
    # Compare book, then chapter, then verse
    order = [:book_index, :chapter, :versenum]

    for method in order
      compare = self.try(method).to_i <=> o.try(method).to_i
      return compare unless compare == 0
    end

    # Otherwise, compare IDs
    return self.id <=> o.id
  end

  # Convert to JSON format
  def as_json(options={})
    {
      :id   => self.id,
      :bk   => self.book,
      :ch   => self.chapter,
      :vs   => self.versenum,
      :tl   => self.translation,
      :ref  => self.ref,
      :text => self.text
    }
  end

  # Abbreviated friendly verse reference: eg. "Jn 3:16"
  #
  # @return [String] translated abbreviated verse reference
  def ref
    "#{Book.find(book_index).abbrev} #{chapter}:#{versenum}"
  end

  # Long friendly verse reference: eg. "John 3:16"
  #
  # @return [String] translated long verse reference
  def ref_long
    bk = Book.find(book_index).name
    bk = "Psalm" if bk == "Psalms"
    "#{bk} #{chapter}:#{versenum}"
  end

  # Return data about testament
  def old_testament?
    book_index < 40
  end

  def new_testament?
    book_index >= 40
  end

  def testament
    book_index >= 40 ? "New" : "Old"
  end

  def history?
    (1..17).include?(book_index) || book_index == 44
  end

  def wisdom?
    (18..22).include?(book_index)
  end

  def prophecy?
    (23..39).include?(book_index) || book_index == 66
  end

  def gospel?
    (40..43).include?(book_index)
  end

  def epistle?
    (45..65).include?(book_index)
  end

  # Returns hash of verses and number of users for each verse
  # @param limit [Fixnum]
  # @param book [Fixnum]
  # @return [Hash]
  def self.rank_verse_popularity(limit=25, book=nil)
    vs_popularity = Hash.new(0)

    if book
      where(book: book).each { |vs| vs_popularity[vs.ref] += vs.memverses_count }
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

  # Check whether verse exists in DB
  # @note Checking for verse in database requires full length book name
  # @param bk [String] Must be full length book name
  # @param ch [Fixnum]
  # @param vs [Fixnum]
  # @param tl [String] Abbreviation of translation (e.g., "NIV")
  # @return [Verse]
  def self.exists_in_db(bk, ch, vs, tl)
    Verse.where(book: bk, chapter: ch, versenum: vs, translation: tl).first
  end

  # Return subsequent verse in same translation (if it exists)
  # @return [Verse]
  def following_verse
    if self.last_in_chapter?
      Verse.exists_in_db(book, chapter.to_i+1, 1, translation)
    else
      Verse.exists_in_db(book, chapter, versenum.to_i+1, translation)
    end
  end

  # Has verse been verified?
  # @return [Boolean]
  def verified?
    return self.verified
  end

  # Is this the last verse of a chapter?
  # @return [Boolean]
  def last_in_chapter?
  	if self.book == "3 John"
  	  if ["NAS", "NLT", "ESV", "ESV07"].include?(self.translation)
  		  return self.versenum.to_i == 15
  	  else
  		  return self.versenum.to_i == 14
  	  end
  	else
      FinalVerse.where(book: book, chapter: chapter, last_verse: versenum).count == 1
    end
  end

  # Find the last verse of the chapter
  # @todo Should no longer be needed now that we have passage model
  # @return [FinalVerse]
  def end_of_chapter_verse
  	if self.book == "3 John"
  		if ["NAS", "NLT", "ESV", "ESV07"].include?( self.translation )
  			FinalVerse.new(book: "3 John", chapter: 1, last_verse: 15)
  		else
  			FinalVerse.new(book: "3 John", chapter: 1, last_verse: 14)
  		end
  	else
    	FinalVerse.where(book: book, chapter: chapter).first
    end
  end

  # Returns array containing all verses in chapter with 'nil' for missing verses
  # @return [Array<Verse>]
  def entire_chapter

    full_chapter  = Array.new
    bk, ch, tl    = book, chapter, translation

    if self.end_of_chapter_verse
      num_verses = self.end_of_chapter_verse.last_verse

      (1..num_verses).each { |vs|
        full_chapter << Verse.exists_in_db(bk, ch, vs, tl)
      }
    end

    return full_chapter
  end

  # Entire chapter in database in this translation?
  # @return [Boolean]
  def entire_chapter_available
    if self.end_of_chapter_verse
      return Verse.where(book: book, chapter: chapter, translation: translation).
                   where("versenum != 0").count == end_of_chapter_verse.last_verse
    else
      return false
    end
  end

  # All tags associated with a given verse
  #  - Gets all tags for all memverses
  #  - Returns most popular tags across all memory verses
  # @return [Hash]
  def all_user_tags(same_tl = false, numtags = 5)

    all_tags = Hash.new(0)

    if same_tl
      self.memverses.each { |mv|
        mv.tags.select { |t| t.name.length < 30 }.each { |tag|
          all_tags[tag] += 1
        }
      }
    else
      self.alternative_translations.each { |tl|
        tl.memverses.each { |mv|
          mv.tags.select { |t| t.name.length < 30 }.each { |tag|
            all_tags[tag] += 1
          }
        }
      }
    end

    return all_tags.sort{|a,b| a[1]<=>b[1]}.reverse[0...numtags]
  end

  # Tag verse with most popular user tags
  #  - when we have millions of users we can restrict tags by translation.
  #  - for now we need the critical mass across translations and can only use top 3 tags
  #  - With settings (true, 5) the tag cloud had 2852 tags as of 3/19/2012.
  #  - Current problem: this doesn't remove old Taggings on Verse model
  def update_tags
    user_tags = self.all_user_tags(false, 3).map { |t| t.first.name }.join(', ') # false = get tags for all translations
    self.tag_list = []
    self.tag_list = user_tags
    self.save
  end

  # Return list of duplicate verses (if any)
  def has_duplicates?
    iv = Hash[
      ["Luke", 12, 34]        => ["Matthew", 6, 21],
      ["Matthew", 6, 21]      => ["Luke", 12, 34],
      ["Proverbs", 14, 12]    => ["Proverbs", 16, 25],
      ["Proverbs", 16, 25]    => ["Proverbs", 14, 12],
      ["Judges", 21, 25]      => ["Judges", 17, 6],
      ["Judges", 17, 6]       => ["Judges", 21, 25],
      ["Matthew", 25, 21]     => ["Matthew", 25, 23],
      ["Matthew", 25, 23]     => ["Matthew", 25, 21],
      ["1 Corinthians", 1, 3] => ["2 Corinthians", 1, 2],      
      ["2 Corinthians", 1, 2] => ["1 Corinthians", 1, 3],      
      ["Leviticus", 19, 30]   => ["Leviticus", 26, 2],
      ["Leviticus", 26, 2]    => ["Leviticus", 19, 30],
      ["Psalms", 107,  8]     => [["Psalms", 107, 15], ["Psalms", 107, 22], ["Psalms", 107, 31]],
      ["Psalms", 107, 15]     => [["Psalms", 107,  8], ["Psalms", 107, 22], ["Psalms", 107, 31]],
      ["Psalms", 107, 22]     => [["Psalms", 107,  8], ["Psalms", 107, 15], ["Psalms", 107, 31]],
      ["Psalms", 107, 31]     => [["Psalms", 107,  8], ["Psalms", 107, 15], ["Psalms", 107, 22]]
    ]

    return iv[ [self.book, self.chapter.to_i, self.versenum.to_i] ] || []
  end

  # Check with biblegateway for correctly entered verse
  # @return [String, nil]
  def web_text
    on_bg = BibleGateway.new(self.translation.to_sym).lookup(self.ref)[:content]
    if on_bg
      on_bg = on_bg.gsub(/[’‘]/, "\'")
      on_bg = on_bg.gsub(/[“”]/, '"')
    end
  end

  # Database text, with normalized quotation marks for comparing with #web_text
  # @return [String]
  def database_text
    in_db = self.text

    # Ok to differ in style of quotation marks
    in_db = in_db.gsub(/[’‘]/, "\'")
    in_db = in_db.gsub(/[“”]/, '"')
  end

  # Compare #web_text and #database_text
  # @return [true, String] true if #web_text and #database_text same, else
  # web_text
  def web_check
    (web_text == database_text) ? true : web_text
  end

  # Link to BibleGateway
  # @return [String]
	def bg_link
		BibleGateway.new(self.translation.to_sym).passage_url(self.ref)
	end

  # Create mnemonic for verse text
  # @return [String]
  def mnemonic

    # Matches Korean Hangul
    if self.text.match /[\uAC00-\uD7A3]/
      self.text.gsub(/([\uAC00-\uD7A3])/) do |m|
        # Calculating lead Jamo of a given Hangul 
        # see http://gernot-katzers-spice-pages.com/var/korean_hangul_unicode.html
        [4352 + (($1.ord - 44032) / 588).floor].pack("U")
      end
    # Matches Chinese characters    
    elsif self.text.match /[\u4E00-\u9FFF]/
      return '-'
    
    # default to Western text
    else
      self.text.gsub(/([\wáâãàçéêíóôõúüñäõÄÕö])([\wáâãàçéêíóôõúüñäõÄÕö]|[\-'’][\wáâãàçéêíóôõúüñäõÄÕö])*/,'\1')
    end

    # In simpler language, the longest regex is matching:
    # (Any alphanumerical character) followed by (all consecutive alphanumerical characters OR a -'’ character
    # followed by an alphanumerical character) The star (*) means we repeat the previous item as many times as
    # possible (refers to set of parentheses matching alphanumerical OR -'’ followed by alphanumerical
    # The '\1' at the end is the value for what we replace these matches with, and it refers to whatever
    # matches the first parentheses (in our case, the first character).
    # Using a '\2' would match the second parentheses, etc. Adapted from JavaScript found at
    # http://productivity501.com/wp-content/uploads/tools/memorize-first-letter-tool.html
  end

  # All translations of this verse
  # @return [Array<Verse>] 
  def alternative_translations
    Verse.where(book: self.book, chapter: self.chapter, versenum: self.versenum)
  end

  # Same verse in different translation
  # @return [Verse, nil]
  def switch_tl(tl)
    alternative_translations.where(translation: tl).first
  end

  # Returns array of all memory verses for a given reference, irrespective of translation
  # @return [Array<Memverse>]
  def all_memory_verses
    all_mv = Array.new

    self.alternative_translations.each { |vs|
      all_mv << vs.memverses
    }

    return all_mv.flatten
  end

  # Is verse locked?
  # @return [Boolean]
  def locked?
    return self.memverses.length > 1
  end

  # Returns Bible book index; case insensitive input
  # @param str [String] Example: 'Deuteronomy' or 'Deut' or 'DEUT'
  # @return [Fixnum, nil] index or nil, if not found
  # @note This breaks if string is not a valid book because you can't add 1 + nil
  # @todo This should not be an instance method, and maybe should not be in this class at all.
  def book_index(str=self.book)
    Book.find_by_name(str).try(:book_index)
  end

  def chapter_name
    book = (self.book == "Psalms") ? "Psalm" : self.book;
    return "#{book} #{self.chapter}"
  end

  # ============= Protected below this line ==================================================================
  protected

  # Abbreviates book names
  # @param book [String] (e.g., 'Deuteronomy')
  # @return [String] abbreviation (e.g., 'Deut')
  def abbr(book)
    return BIBLEABBREV[book_index(book)-1]
  end

  # ============= Private below this line - can only be called on self =======================================
  private

  # Delete associated memverses to prevent orphaning [hook: before_destroy]
  def delete_memverses
    Rails.logger.warn("*** Deleting the following verse: #{self.ref} [#{self.translation}]")
    Rails.logger.warn("*** Deleting associated memory verses")
    Rails.logger.warn("*** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    self.memverses.each { |mv|
      Rails.logger.warn("*** #{mv.user.name_or_login}")
    }

    self.memverses.destroy_all
  end

  # Clean up text [hook: before_save]
  def cleanup_text
    self.text = self.text.gsub(/(\r)?\n/,'').squeeze(" ").strip
    self.text = self.text.gsub(" -"," —").gsub("- ","— ") # prefer em dashes
    self.text = self.text.gsub(/[<>]/,'')
  end

  # Schedule [VerseWebCheck] [hook: after_save]
  # @return [void]
  def schedule_web_check
    VerseWebCheck.perform_async(self.id) unless verified?
  end

  # Validate reference [hook: before_create]
  # @return [Boolean]
  def validate_ref
    verse = Verse.exists_in_db(book, chapter, versenum, translation)
    final_verse = FinalVerse.where(book: book, chapter: chapter).first

    if verse
      errors.add(:base, "Verse already exists in #{translation}")
      return false
    elsif !final_verse
      errors.add(:base, "Invalid chapter")
      return false
    elsif versenum > final_verse.last_verse
      errors.add(:base, "Invalid verse number")
      return false
    else
      return true
    end
  end

  # Link to [Uberverse] [hook: after_create]
  def associate_with_uberverse
    uv = Uberverse.where(book: book, chapter: chapter, versenum: versenum).first
    self.uberverse_id = uv.id unless !uv
  end

end
