class Book

  # TODO: Convert BIBLEBOOKS to_json and do something very similar client-side JS.

  attr_reader :book_index
  attr_reader :locale

  def initialize(index,locale=nil)
    @book_index = index

    if BIBLEBOOKS.keys.include?(locale)
      @locale = locale
    else
      @locale = :en
    end
  end

  # Find book by index. User language is used.
  # @param index [Fixnum] Index of Bible book
  # @return [Book]
  def self.find(index)
    locale = I18n.locale
    new(index,locale)
  end

  # Tries finding book by name and abbreviation in any language
  # @param name [String] name or abbreviation
  # @return [Book] Book with appropriate language
  def self.find_by_name(name)
    for lang in BIBLEBOOKS.keys
      index = BIBLEBOOKS[lang].values.map(&:downcase).index(name.downcase)
      index ||= BIBLEBOOKS[lang].keys.map(&:downcase).index(name.downcase)
      break if index
    end

    return index.nil? ? nil : Book.new(index+1,lang)
  end

  # @return [String] Name of book in given language
  def name
    BIBLEBOOKS[locale].values[book_index-1]
  end

  # @return [String] Abbreviation of book in given language
  def abbrev
    BIBLEBOOKS[locale].keys[book_index-1]
  end

  # @param lang [Symbol] (e.g., :en, :es)
  # @return [Book]
  def to_lang(lang)
    if BIBLEBOOKS.keys.include?(lang)
      Book.new(book_index, lang)
    else
      raise ArgumentError, 'specified lang is not supported for Book'
      self
    end
  end
end
