class Translation

  # Public: Return TRANSLATIONS without given translation(s).
  #
  # trans - The Symbol or Array of Symbols for the translation(s) to exclude
  #
  # Returns the Hash of translations.
  def self.exclude(trans = nil)
    translations = TRANSLATIONS.dup

    if trans.is_a?(Array)
      trans.each { |k| translations.delete(k) }
    elsif trans.is_a?(Symbol)
      translations.delete(trans)
    end

    translations
  end

  # Public: Get and sort translations with given language.
  #
  # lang  - String for the language abbreviation (e.g., "en").
  # trans - Hash of translations to filter (default: TRANSLATIONS).
  #
  # Returns Array of translations, nicely formatted, with abbreviation.
  #   Example: ["Version Name (VN)", "VN"]
  def self.with_lang(lang, trans = TRANSLATIONS)
    trans_ = Array.new

    trans.each {|key, val|
      trans_ << ["#{val[:name]} (#{key})", key.to_s] if val[:language] == lang
    }

    return trans_.sort
  end

  # Public: Return translations ready for Rails grouped_options_for_select
  #
  # options - Hash of options (default: {}):
  #           :except - The Symbol or Array of Symbols of translations
  #                     to exclude
  #
  # Returns the Hash of languages in user's language, with the translations
  #   for each language. Languages are sorted by key (e.g., EN, ES, etc.) with
  #   user's language first, and translations sorted within the languages.
  def self.select_options(options = {})
    translations = Translation.exclude(options[:except] || nil)
    languages = []; select = {}

    # Get language name -- in user's language, if possible
    lang_name = lambda { |abbrev| I18n.t abbrev.to_s, scope: [:language]  }

    # get array of all languages
    translations.each_value {|value| languages << value[:language]}
    # sort languages, put user's first, and remove duplicates
    languages = languages.sort.unshift(I18n.locale).uniq

    for lang in languages
      select["#{lang_name.call(lang)} (#{lang.upcase})"] =
        Translation.with_lang(lang, translations)
    end

    select
  end

end
