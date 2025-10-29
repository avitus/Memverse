class Passage < ApplicationRecord

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :Passage do
    key :required, [:id, :ref, :book, :chapter, :first_verse, :last_verse]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :user_id do
      key :type, :integer
      key :format, :int64
    end
    property :ref do
      key :type, :string
      key :description, 'The passage reference (e.g., "John 3:16-18")'
    end
    property :book do
      key :type, :string
    end
    property :book_index do
      key :type, :integer
      key :format, :int64
    end
    property :chapter do
      key :type, :integer
      key :format, :int64
    end
    property :first_verse do
      key :type, :integer
      key :format, :int64
    end
    property :last_verse do
      key :type, :integer
      key :format, :int64
    end
    property :interval_array do
      key :type, :array
      items do
        key :type, :integer
      end
      key :description, 'Array of test intervals for verses in the passage'
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------

  belongs_to :user

  # We would like to be able to destroy a passage and have all the accompanying memverses be destroyed.
  # This will not work because destroying a memverse results in the entire passage being reformulated and 
  # causes infinite loops. See the .remove() method below
  # has_many   :memverses , :dependent => :destroy  

  has_many   :memverses
  has_many   :verses, :through => :memverses

  validates_presence_of :user_id, :length, :book, :chapter, :first_verse, :last_verse

  # attr_protected :test_interval

  scope :due,    -> { where('passages.next_test  <= ?', Date.today) }
  scope :active, -> { joins(:memverses).merge(Memverse.active).group(:id).having('count(memverses.id) > 0') }

  after_create   :update_ref
  after_create   :update_book_index

  paginates_per 50 # number of passages per page via API

  # Convert to JSON format
  def as_json(options={})
    {
      :id              => self.id,
      :user_id         => self.user_id,
      :ref             => self.reference,       # TODO: It was a bad idea to rename the attribute
      :book            => self.book,
      :book_index      => self.book_index,
      :chapter         => self.chapter,
      :first_verse     => self.first_verse,
      :last_verse      => self.last_verse,
      :interval_array  => self.interval_array
    }

    # It would probably be preferable to handle all 'as_json' using super as far as possible
    # as this would preserve flexibility for the future. That would require using 'reference'
    # rather than 'ref' as we did above. (Only code using ref is in reviewState.Initialize)
    # For now, a complete override as above is ok since we aren't using too many attributes.
    #
    # super(options.reverse_merge(:methods => :interval_array, :only => [:id, :reference]))
  end

  # Automatically create subsections for passage
  def auto_subsection( subsection_length = 4, max_subsection_length = 10 )

    if self.length > subsection_length
      # Create an array of object with the following structure
      # [ memverse_id, verse_num, subsection_end_probability ]
      auto_ss = self.memverses.joins(verse: :uberverse)
                              .select(['uberverses.subsection_end, verses.versenum, memverses.id'])
                              .order('verses.versenum')

      section_dividers = auto_ss.pluck(:subsection_end) # Array of probabilities that each verse ends a section
      
      # Filter out nil values and convert to integers to ensure consistency
      valid_dividers = section_dividers.compact.map(&:to_i)

      # Check if we have any valid dividers to work with
      if valid_dividers.empty?
        # If no valid subsection data, set all memverses to subsection 0
        auto_ss.each { |mv| 
          Memverse.find(mv.id).update_attribute(:subsection, 0)
        }
        return
      end

      # Calculate the desired number of subsections
      num_sections = (self.length / subsection_length).to_i

      # Set threshold based on number of subsections needed. Don't set threshold below 1.
      # Handle case where we have fewer valid dividers than sections needed
      if valid_dividers.length >= num_sections
        threshold = [ valid_dividers.sort[-num_sections], 1].max
      else
        threshold = 1 # Default threshold if insufficient data
      end

      # puts ("Section dividers: #{section_dividers.inspect}")
      # puts ("Number of sections: #{num_sections}")
      # puts ("Sorted section dividers: #{valid_dividers.sort}")
      # puts ("Setting threshold: #{threshold}")

      auto_ss.each_with_index { |mv, index|
        # Use original section_dividers array but handle nil values in comparison
        dividers_to_check = section_dividers[0...index].compact
        Memverse.find(mv.id).update_attribute(:subsection, dividers_to_check.select{ |div| div.to_i >= threshold }.count)
      }
    end

  end

  # Combine two passages into one. Method accepts an optional join (linking) verse.
  # @note Order of join doesn't matter
  def absorb( second_passage, join_mv=nil )

    self.first_verse = [self.first_verse, second_passage.first_verse].min
    self.last_verse  = [self.last_verse,  second_passage.last_verse ].max
    self.length      = self.last_verse - self.first_verse + 1  # uses values calculated in prior two lines

    # Associate all memory verses from second passage with this passage
    second_passage.memverses.each { |mv| mv.update_attribute( :passage_id, self.id ) }
    join_mv.update_attribute( :passage_id, self.id ) unless !join_mv

    # Delete second passage
    second_passage.destroy

    consolidate_supermemo
    update_ref
    entire_chapter_flag_check
    save!

  end

  # Removing all the memory verses for a given passages ensures that the passage itself will be deleted
  # This is causing a problem ... somehow multiple empty passages are being created.
  def remove
    self.memverses.destroy_all
  end

  # Add a memory verse into a passage
  def expand( mv )

    self.first_verse = [ self.first_verse, mv.verse.versenum ].min
    self.last_verse  = [ self.last_verse,  mv.verse.versenum ].max
    self.length += 1

    # Associate memory verse with passage
    mv.update_attribute( :passage_id, self.id )

    consolidate_supermemo
    update_ref
    entire_chapter_flag_check
    save

  end

  # Update Reference
  def update_ref

    book = (self.book == "Psalms") ? "Psalm" : self.book;

    if self.length == 1
      self.reference = book + ' ' + self.chapter.to_s + ':' + self.first_verse.to_s
    else
      self.reference = book + ' ' + self.chapter.to_s + ':' + self.first_verse.to_s + '-' + self.last_verse.to_s
    end
    save
    # return self.reference
  end

  def update_book_index
    self.book_index = Book.find_by_name(self.book).try(:book_index)
    save
  end

  # Combine supermemo information from underlying verses
  def consolidate_supermemo
    self.test_interval = self.memverses.active.minimum(:test_interval)
    self.rep_n         = self.memverses.active.minimum(:rep_n)
    self.last_tested   = self.memverses.active.maximum(:last_tested)
    self.next_test     = self.memverses.active.minimum(:next_test)
    self.efactor       = self.memverses.active.average(:efactor)
    save
  end

  # Update next_test date
  def update_next_test_date
    self.next_test     = self.memverses.active.minimum(:next_test)
    save
  end

  # Set flag if entire chapter has been added to memorization list
  def entire_chapter_flag_check

    # Corner case for 3 John 1. Not elegant but should usually drop through to primary case
    if book == "3 John" && chapter == 1 && first_verse == 1

      if ["NAS", "NLT", "ESV", "ESV07"].include?( self.translation )
        update_attribute( :complete_chapter, last_verse == 15 )
      else
        update_attribute( :complete_chapter, last_verse == 14 )
      end

    # All other chapters
    else

      # Only look up FinalVerse when first_verse is 1 or 0
      final_verse_record = FinalVerse.where(:book => book, :chapter => chapter).first
      if ( self.first_verse == 1 || self.first_verse == 0 ) && final_verse_record && ( self.last_verse == final_verse_record.last_verse )
        update_attribute( :complete_chapter, true )
      else
        update_attribute( :complete_chapter, false )
      end

    end

  end

  # Return array containing the memorization interval of each memverse in passage
  # @return [Array<Integer>]
  def interval_array
    self.memverses.pluck(:test_interval)
  end

end
